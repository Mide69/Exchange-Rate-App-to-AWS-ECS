import pytest
from app import app, get_exchange_rate

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_index_route(client):
    """Test the main route returns 200"""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Exchange Rates' in response.data

def test_get_exchange_rate():
    """Test exchange rate function returns expected structure"""
    result = get_exchange_rate()
    assert isinstance(result, dict)
    assert 'error' in result or ('ngn_to_usd' in result and 'usd_to_ngn' in result)