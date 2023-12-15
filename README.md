# mock-prediction-market

- Mock Prediction Market

-----

## Development

- [foundry](https://book.getfoundry.sh/)

### features

1. depositToPredictionMarket
2. buyOrder
3. sellOrder
4. cancelOrder
5. buyTrade
6. sellTrade
7. resolvePredictionMarket
8. withdraw

### Test case(sample)

```linux
Running 17 tests for test/MockPredictionMarket/MockPredictionMarket.t.sol:TestMockPredictionMarket
[PASS] test_NG_MockPredictionMarket_buyOrder_byOwner() (gas: 25856)
[PASS] test_NG_MockPredictionMarket_buyTrade_byOwner() (gas: 23717)
[PASS] test_NG_MockPredictionMarket_cancelOrder_bySeller() (gas: 141866)
[PASS] test_NG_MockPredictionMarket_depositToPredictionMarket_byOwner() (gas: 23633)
[PASS] test_NG_MockPredictionMarket_resolvePredictionMarket_byBuyer() (gas: 15290)
[PASS] test_NG_MockPredictionMarket_sellOrder_byOwner() (gas: 19208)
[PASS] test_NG_MockPredictionMarket_sellTrade_byOwner() (gas: 19219)
[PASS] test_OK_MockPredictionMarket_buyOrder_byBuyer() (gas: 115678)
[PASS] test_OK_MockPredictionMarket_buyTrade_byBuyer() (gas: 313073)
[PASS] test_OK_MockPredictionMarket_cancelOrder_byBuyer() (gas: 127700)
[PASS] test_OK_MockPredictionMarket_cancelOrder_bySeller() (gas: 136748)
[PASS] test_OK_MockPredictionMarket_depositToPredictionMarket_bySeller() (gas: 51244)
[PASS] test_OK_MockPredictionMarket_resolvePredictionMarket_FALSE_byOwner() (gas: 43970)
[PASS] test_OK_MockPredictionMarket_resolvePredictionMarket_TRUE_byOwner() (gas: 19166)
[PASS] test_OK_MockPredictionMarket_sellOrder_bySeller() (gas: 149021)
[PASS] test_OK_MockPredictionMarket_sellTrade_bySeller() (gas: 191214)
[PASS] test_OK_MockPredictionMarket_withdraw_FALSE_byOwner() (gas: 37591)
Test result: ok. 17 passed; 0 failed; 0 skipped; finished in 4.41ms
```
