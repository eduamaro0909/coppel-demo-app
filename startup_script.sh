    #!/bin/bash

# Create project directory
mkdir ecommerce_api
cd ecommerce_api

# Create necessary directories and files
mkdir app migrations tests
touch app/__init__.py app/config.py app/models.py app/routes.py app/auth.py app/utils.py app/swagger.py app/cart.py
touch tests/__init__.py tests/test_routes.py
touch .env .gitignore requirements.txt run.py README.md

# Populate requirements.txt
echo "Flask
Flask-SQLAlchemy
Flask-Migrate
Flask-JWT-Extended
flasgger
psycopg2-binary" > requirements.txt

# Populate app/__init__.py
echo "from flask import Flask
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_jwt_extended import JWTManager
from flasgger import Swagger
from .config import Config

db = SQLAlchemy()
migrate = Migrate()
jwt = JWTManager()
swagger = Swagger()

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)

    db.init_app(app)
    migrate.init_app(app, db)
    jwt.init_app(app)
    swagger.init_app(app)

    from .routes import main as main_blueprint
    app.register_blueprint(main_blueprint)

    from .auth import auth as auth_blueprint
    app.register_blueprint(auth_blueprint)

    from .cart import cart as cart_blueprint
    app.register_blueprint(cart_blueprint)

    return app" > app/__init__.py

# Populate app/config.py
echo "import os

class Config:
    SECRET_KEY = os.getenv('SECRET_KEY', 'my_secret_key')
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'postgresql://user:password@localhost:5432/ecommerce_db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'my_jwt_secret_key')" > app/config.py

# Populate app/models.py
echo "from . import db
from werkzeug.security import generate_password_hash, check_password_hash

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)

    def set_password(self, password):
        self.password_hash = generate_password_hash(password)

    def check_password(self, password):
        return check_password_hash(self.password_hash, password)

class Product(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    description = db.Column(db.Text, nullable=True)
    price = db.Column(db.Float, nullable=False)

class Cart(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    user = db.relationship('User', backref=db.backref('carts', lazy=True))

class CartItem(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    cart_id = db.Column(db.Integer, db.ForeignKey('cart.id'), nullable=False)
    product_id = db.Column(db.Integer, db.ForeignKey('product.id'), nullable=False)
    quantity = db.Column(db.Integer, nullable=False)
    cart = db.relationship('Cart', backref=db.backref('items', lazy=True))
    product = db.relationship('Product')" > app/models.py

# Populate app/auth.py
echo "from flask import Blueprint, jsonify, request
from .models import User
from . import db
from flask_jwt_extended import create_access_token

auth = Blueprint('auth', __name__)

@auth.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    if User.query.filter_by(username=username).first():
        return jsonify({'msg': 'Username already exists'}), 400

    new_user = User(username=username)
    new_user.set_password(password)
    db.session.add(new_user)
    db.session.commit()

    return jsonify({'msg': 'User created successfully'}), 201

@auth.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    user = User.query.filter_by(username=username).first()
    if user and user.check_password(password):
        access_token = create_access_token(identity=username)
        return jsonify(access_token=access_token), 200

    return jsonify({'msg': 'Invalid username or password'}), 401" > app/auth.py

# Populate app/routes.py
echo "from flask import Blueprint, jsonify, request
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

Product.to_dict = to_dict" > app/routes.py

# Populate app/cart.py
echo "from flask import Blueprint, jsonify, request
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

    return jsonify({'msg': 'Product added to cart'}), 201" > app/cart.py

# Populate app/swagger.py
echo "from flasgger import Swagger

def init_swagger(app):
    swagger = Swagger(app)
    return swagger" > app/swagger.py

# Populate run.py
echo "from app import create_app

app = create_app()

if __name__ == '__main__':
    app.run(debug=True)" > run.py

# Populate .env
echo "SECRET_KEY=your_secret_key
DATABASE_URL=postgresql://user:password@localhost:5432/ecommerce_db
JWT_SECRET_KEY=your_jwt_secret_key" > .env

# Populate .gitignore
echo "*.pyc
__pycache__/
instance/
.webassets-cache
.env
.venv
venv/
ENV/
env/
*.pyo
*.pyd
.Python
*.sqlite3
*.db
*.log
*.pot
*.mo" > .gitignore

# Populate tests/test_routes.py
echo "import unittest
from app import create_app, db

class TestRoutes(unittest.TestCase):

    def setUp(self):
        self.app = create_app()
        self.app.config['TESTING'] = True
        self.app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
        self.client = self.app.test_client()

        with self.app.app_context():
            db.create_all()

    def tearDown(self):
        with self.app.app_context():
            db.session.remove()
            db.drop_all()

    def test_get_products(self):
        response = self.client.get('/products')
        self.assertEqual(response.status_code, 200)

if __name__ == '__main__':
    unittest.main()" > tests/test_routes.py

# Populate README.md
echo "# Coppel Day

## Description

This project is a REST API for an ecommerce platform, developed using Flask. The API allows CRUD operations on products and users, includes JWT authentication, and is documented with Swagger.

## Project Structure

\`\`\`
ecommerce_api/
│
├── app/
│   ├── __init__.py
│   ├── config.py
│   ├── models.py
│   ├── routes.py
│   ├── auth.py
│   ├── utils.py
│   ├── swagger.py
│   └── cart.py
│
├── migrations/
│
├── tests/
│   ├── __init__.py
│   └── test_routes.py
│
├── .env
├── .gitignore
├── requirements.txt
└── run.py
\`\`\`

## Requirements

- Python 3.8+
- PostgreSQL
- pip

## Installation

1. Clone the repository:
    \`\`\`sh
    git clone https://github.com/your_username/coppel_day.git
    cd coppel_day
    \`\`\`

2. Create and activate a virtual environment:
    \`\`\`sh
    python -m venv venv
    source venv/bin/activate  # On Windows use \`venv\\Scripts\\activate\`
    \`\`\`

3. Install the dependencies:
    \`\`\`sh
    pip install -r requirements.txt
    \`\`\`

4. Configure the environment variables in the \`.env\` file:
    \`\`\`env
    SECRET_KEY=your_secret_key
    DATABASE_URL=postgresql://user:password@localhost:5432/ecommerce_db
    JWT_SECRET_KEY=your_jwt_secret_key
    \`\`\`

5. Initialize the database:
    \`\`\`sh
    flask db init
    flask db migrate -m \"Initial migration\"
    flask db upgrade
    \`\`\`

## Running the Application

To run the application locally, use the following command:

\`\`\`sh
python run.py
\`\`\`

The application will be available at \`http://127.0.0.1:5000/\`.

## Endpoints

### Authentication

- **POST /register**: User registration
- **POST /login**: User login

### Products

- **GET /products**: Get all products
- **GET /products/<int:id>**: Get a product by ID
- **POST /products**: Create a new product (requires authentication)
- **PUT /products/<int:id>**: Update a product (requires authentication)
- **DELETE /products/<int:id>**: Delete a product (requires authentication)

### Cart

- **GET /cart**: Get the current user's cart (requires authentication)
- **POST /cart**: Add a product to the cart (requires authentication)

## Testing

To run the tests, use the following command:

\`\`\`sh
python -m unittest discover -s tests
\`\`\`

## Swagger

The Swagger documentation will be available at \`http://127.0.0.1:5000/apidocs\`.

## Contributing

1. Fork the project.
2. Create a new branch (\`git checkout -b feature/new-feature\`).
3. Make your changes and commit them (\`git commit -am 'Add new feature'\`).
4. Push your changes to the branch (\`git push origin feature/new-feature\`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License." > README.md./