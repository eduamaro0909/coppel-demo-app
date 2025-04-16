from flask import Blueprint, jsonify, request
from .models import Product
from . import db
from flask_jwt_extended import jwt_required

main = Blueprint('main', __name__)

@main.route('/products', methods=['GET'])
def get_products():
    products = Product.query.all()
    return jsonify([product.to_dict() for product in products])

@main.route('/products/<int:id>', methods=['GET'])
def get_product(id):
    product = Product.query.get_or_404(id)
    return jsonify(product.to_dict())

@main.route('/products', methods=['POST'])
@jwt_required()
def create_product():
    data = request.get_json()
    new_product = Product(
        name=data.get('name'),
        description=data.get('description'),
        price=data.get('price')
    )
    db.session.add(new_product)
    db.session.commit()
    return jsonify(new_product.to_dict()), 201

@main.route('/products/<int:id>', methods=['PUT'])
@jwt_required()
def update_product(id):
    product = Product.query.get_or_404(id)
    data = request.get_json()
    product.name = data.get('name')
    product.description = data.get('description')
    product.price = data.get('price')
    db.session.commit()
    return jsonify(product.to_dict())

@main.route('/products/<int:id>', methods=['DELETE'])
@jwt_required()
def delete_product(id):
    product = Product.query.get_or_404(id)
    db.session.delete(product)
    db.session.commit()
    return jsonify({'msg': 'Product deleted'}), 204

def to_dict(self):
    return {
        'id': self.id,
        'name': self.name,
        'description': self.description,
        'price': self.price
    }

Product.to_dict = to_dict
