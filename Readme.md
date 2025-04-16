
# Coppel Day

## Description

This project is a REST API for an ecommerce platform, developed using Flask. The API allows CRUD operations on products and users, includes JWT authentication, and is documented with Swagger.


## Requirements

- Python 3.8+
- PostgreSQL
- pip

## Installation

1. Clone the repository:
    ```sh
    git clone https://github.com/your_username/coppel_day.git
    cd coppel_day
    ```

2. Create and activate a virtual environment:
    ```sh
    python -m venv venv
    source venv/bin/activate  # On Windows use `venv\Scripts\activate`
    ```

3. Install the dependencies:
    ```sh
    pip install -r requirements.txt
    ```

4. Configure the environment variables in the `.env` file:
    ```env
    SECRET_KEY=your_secret_key
    DATABASE_URL=postgresql://user:password@localhost:5432/ecommerce_db
    JWT_SECRET_KEY=your_jwt_secret_key
    ```

5. Initialize the database:
    ```sh
    flask db init
    flask db migrate -m "Initial migration"
    flask db upgrade
    ```

## Running the Application

To run the application locally, use the following command:

```sh
python run.py
```

The application will be available at `http://127.0.0.1:5000/`.

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

## Testing

To run the tests, use the following command:

```sh
python -m unittest discover -s tests
```

## Swagger

The Swagger documentation will be available at `http://127.0.0.1:5000/apidocs`.

## Contributing

1. Fork the project.
2. Create a new branch (`git checkout -b feature/new-feature`).
3. Make your changes and commit them (`git commit -am 'Add new feature'`).
4. Push your changes to the branch (`git push origin feature/new-feature`).
5. Open a Pull Request.

## License

This project is licensed under the MIT License.