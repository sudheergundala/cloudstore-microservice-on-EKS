# Here we will be creating the security groups for ALB, EKS, RDS and Elastic Cache. 
# After creating the security groups we will be assigning the inbound and outbound rules. 
# Note: we will strictly follow the SG reference rules and we will be allowing all egress rule to EKS. 
#       Also we will be creating rules for each resource. 

# Security Group for ALB - Internet facing

resource "aws_security_group" "alb" {
  name_prefix = "${var.name_prefix}-alb-"
  vpc_id      = var.vpc_id
  description = "Security group for Application Load balancer"
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-alb-sg"
  })
  lifecycle {
    create_before_destroy = true
  }
}

# Inbound rule for ALB Security group - HTTPS from internet(443)

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  description       = "HTTPS rule for alb"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
}

# Inbound rule for ALB Security group - HTTP from internet(80). Typically redirected to HTTPS. 

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  ip_protocol       = "tcp"
  description       = "HTTP rule for alb"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

# ALB outbound to EKS Nodes

resource "aws_vpc_security_group_egress_rule" "alb_to_eks" {
  security_group_id            = aws_security_group.alb.id
  ip_protocol                  = "-1"
  description                  = "To EKS node"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# EKS Security group

resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.name_prefix}-eks-nodes-"
  description = "Security group for EKS nodes"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-eks-nodes-sg"
  })
  lifecycle {
    create_before_destroy = true
  }
}

# EKS Security group inbound rules - from ALB security group only

resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id            = aws_security_group.eks_nodes.id
  description                  = "Allow inbound traffic only from ALB"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
}

# EKS inbound node-to-node (pods communicating, kubelet, etc)

resource "aws_vpc_security_group_ingress_rule" "eks_self" {
  security_group_id            = aws_security_group.eks_nodes.id
  ip_protocol                  = "-1"
  description                  = "node to node communication"
  referenced_security_group_id = aws_security_group.eks_nodes.id
}

# EKS outbound all (Pull images, call AWS APIs via NAT)

resource "aws_vpc_security_group_egress_rule" "eks_all" {
  ip_protocol       = "-1"
  security_group_id = aws_security_group.eks_nodes.id
  description       = "All outbound traffic"
  cidr_ipv4         = "0.0.0.0/0"
}

# RDS security group -- (postgreSQL accepts inbound from EKS only)

resource "aws_security_group" "rds" {
  name_prefix = "${var.name_prefix}-rds-"
  description = "security group for RDS postgreSQL"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-rds-sg"
  })
  lifecycle {
    create_before_destroy = true
  }
}


# RDS inbound: PostgreSQL (5432) accepts from EKS only - here we dont need egress because SG is stateful. 
# so it will send the traffic back to eks automatically. 

resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  description                  = "postgreSQL from EKS nodes"
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 5432
  to_port                      = 5432
}

# Elasticache Security group - Redis/valkey only accepts connection from EKS

resource "aws_security_group" "elasticache" {
  name_prefix = "${var.name_prefix}-elasticache-"
  description = "security group for elasticache"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "${var.name_prefix}-elasticache-sg"
  })
  lifecycle {
    create_before_destroy = true
  }
}

# Elasticache inbound : Redis/valkey (6379) from EKS nodes only. No egress needed because SG is stateful. 

resource "aws_vpc_security_group_ingress_rule" "elasticache_from_Eks" {
  security_group_id            = aws_security_group.elasticache.id
  description                  = "Redis accepts inbound only from EKS nodes"
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id
  from_port                    = 6379
  to_port                      = 6379
}