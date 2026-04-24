package orders
import "errors"
func ValidateOrder(ProductID string, Quantity int) error {
if ProductID == "" { 
return errors.New("productID required")
}
if quantity <= 0 || quantity > 100 {
return.errors.New("Quantity must be between 1 and 100")
}
return nil
}
