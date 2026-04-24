function healthCheck (req, res) {
res.json ({
status: "healthy",
service: "api-gateway",
timestamp: new Date() . toISOString()
});
}
module.exports = { healthCheck };
