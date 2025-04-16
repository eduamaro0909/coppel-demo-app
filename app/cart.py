from flask import Blueprint, jsonify, request
from .models import Cart, CartItem, Product, User
from . import db
from flask_jwt_extended import jwt_required, get_jwt_identity

cart = Blueprint('cart', __name__)

@cart.route('/cart', methods=['GET'])
@jwt_required()
def get_cart():
    current_user = get_jwt_identity()
    user = User.query.filter_by(username=current_user).first()
    cart = Cart.query.filter_by(user_id=user.id).first()

    if not cart:
        return jsonify({'msg': 'Cart is empty'}), 200

    items = CartItem.query.filter_by(cart_id=cart.id).all()
    cart_items = [{'product_id': item.product_id, 'quantity': item.quantity} for item in items]

    return jsonify(cart_items), 200

@cart.route('/cart', methods=['POST'])
@jwt_required()
def add_to_cart():
    current_user = get_jwt_identity()
    user = User.query.filter_by(username=current_user).first()
    data = request.get_json()
    product_id = data.get('product_id')
    quantity = data.get('quantity')

    if not product_id or not quantity:
        return jsonify({'msg': 'Product ID and quantity are required'}), 400

    product = Product.query.get(product_id)
    if not product:
        return jsonify({'msg': 'Product not found'}), 404

    cart = Cart.query.filter_by(user_id=user.id).first()
    if not cart:
        cart = Cart(user_id=user.id)
        db.session.add(cart)
        db.session.commit()

    cart_item = CartItem.query.filter_by(cart_id=cart.id, product_id=product_id).first()
    if cart_item:
        cart_item.quantity += quantity
    else:
        cart_item = CartItem(cart_id=cart.id, product_id=product_id, quantity=quantity)
        db.session.add(cart_item)

    db.session.commit()

    return jsonify({'msg': 'Product added to cart'}), 201
