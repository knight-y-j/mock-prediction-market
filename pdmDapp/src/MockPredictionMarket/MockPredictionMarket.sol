// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// library
library CalcMath {
    function _add(
        uint256 x_,
        uint256 y_
    ) internal pure returns (uint256 total_) {
        uint256 z_ = x_ + y_;

        require(z_ >= x_);

        total_ = z_;
    }

    function _sub(
        uint256 x_,
        uint256 y_
    ) internal pure returns (uint256 total_) {
        require(x_ >= y_);

        total_ = x_ - y_;
    }

    function _dev(
        uint256 x_,
        uint256 y_
    ) internal pure returns (uint256 total_) {
        total_ = x_ / y_;
    }
}

/// struct
enum ORDERTYPE {
    BUY,
    SELL
}

enum RESULTSTATUS {
    CLOSE,
    OPEN,
    YES,
    NO
}

struct ORDER {
    address _orderer;
    ORDERTYPE _orderType;
    uint256 _amount;
    uint256 _price;
}

/// event handling
interface EventMockPredictionMarket {
    event DepositToPredictionMarketEvent(
        address indexed depositor_,
        uint256 indexed amount_
    );

    event BuyOrderEvent(
        address indexed buyer_,
        uint256 indexed orderID_,
        uint256 price_,
        uint256 amount_
    );

    event SellOrderEvent(
        address indexed seller_,
        uint256 indexed orderID_,
        uint256 price_,
        uint256 amount_
    );

    event CancelOrderEvent(
        address indexed orderer_,
        uint256 indexed orderID_,
        uint256 price_,
        uint256 amount_
    );

    event TradeMatchEvent(
        address indexed buyer_,
        address indexed seller_,
        uint256 indexed orderID_,
        uint256 amount_
    );

    event ResolvePredictionMarketEvent(
        address indexed owner_,
        RESULTSTATUS indexed resultStatus_
    );
}

/// interfaces
interface IMockPredictionMarket {
    /*
     * @dev depositToPredictionMarket()
     * - deposit to prediction market
     * @return bool isDeposit_
     */
    function depositToPredictionMarket()
        external
        payable
        returns (bool isDeposit_);

    /*
     * @dev buyOrder()
     * - order buy share
     * @param uint256 price_ is share of price
     * @return bool isBuyOrder_
     */
    function buyOrder(
        uint256 price_
    ) external payable returns (bool isBuyOrder_);

    /*
     * @dev sellOrder()
     * - order sell share
     * @param uint256 price_ is share of price
     * @param uint256 amount_ is sell of amount
     * @return bool isSellOrder_
     */
    function sellOrder(
        uint256 price_,
        uint256 amount_
    ) external returns (bool isSellOrder_);

    /*
     * @dev cancelOrder()
     * - cancel order buy and sell
     * @param uint256 orderID_ is order id
     * @return bool isCancelOrder_
     */
    function cancelOrder(
        uint256 orderID_
    ) external returns (bool isCancelOrder_);

    /*
     * @dev buyTrade()
     * - trade sell order
     * @param uint256 orderID_ is order id
     * @return bool isBuyTrade_
     */
    function buyTrade(
        uint256 orderID_
    ) external payable returns (bool isBuyTrade_);

    /*
     * @dev sellTrade()
     * - trade buy order
     * @param uint256 orderID_ is order id
     * @param uint256 amount_ is sell of amount
     * @return bool isSellTrade_
     */
    function sellTrade(
        uint256 orderID_,
        uint256 amount_
    ) external returns (bool isSellTrade_);

    /*
     * @dev resolvePredictionMarket()
     * - cancel order buy and sell
     * @param bool predictionResult_ is result
     * @return bool isPredictionResult_
     * - access control
     * - caller is only contract owner
     */
    function resolvePredictionMarket(
        bool predictionResult_
    ) external returns (bool isPredictionResult_);

    /*
     * @dev withdraw()
     * - withdraw from prediction market contract
     * @return bool isWithdraw_
     */
    function withdraw() external returns (bool isWithdraw_);
}

/// contract
contract MockPredictionMarket is
    IMockPredictionMarket,
    EventMockPredictionMarket
{
    using CalcMath for uint256;

    uint256 private constant TX_FEE_NUMERATOR = 1;
    uint256 private constant TX_FEE_DENOMINATOR = 500;

    address private _owner;
    RESULTSTATUS private _resultStatus;
    uint256 private _deadlineTime;
    uint256 private _orderID;
    uint256 private _collateral;
    mapping(uint256 orderID => ORDER) private _orders;
    mapping(address account => uint256) private _shares;
    mapping(address account => uint256) private _balances;

    constructor(uint256 periodTime_) payable {
        require(
            msg.sender != address(0) && msg.value > 0 && periodTime_ > 0,
            "invalid value"
        );
        require(
            _resultStatus == RESULTSTATUS.CLOSE,
            "prediction result not yet open"
        );
        _owner = msg.sender;

        _initialPredictionMarket(msg.sender, periodTime_, msg.value);
    }

    function _initialPredictionMarket(
        address owner_,
        uint256 periodTime_,
        uint256 amount_
    ) internal onlyOwner {
        _resultStatus = RESULTSTATUS.OPEN;

        _deadlineTime = _deadlineTime._add(periodTime_._add(block.timestamp));

        _deposit(owner_, amount_);
    }

    function depositToPredictionMarket()
        external
        payable
        override
        validDeadLine
        onlyDepositor
        returns (bool isDeposit_)
    {
        require(msg.sender != address(0) && msg.value > 0, "invalid value");

        _depositToPredictionMarket(msg.sender, msg.value);

        isDeposit_ = true;
    }

    function _depositToPredictionMarket(
        address account_,
        uint256 amount_
    ) internal returns (bool isDeposit_) {
        _deposit(account_, amount_);

        isDeposit_ = true;
    }

    function _deposit(address depositor_, uint256 amount_) internal {
        _shares[depositor_] = _shares[depositor_]._add(amount_._dev(100)); // Note: 1 share = 100 wei
        _collateral = _collateral._add(amount_);

        emit DepositToPredictionMarketEvent(depositor_, amount_);
    }

    function buyOrder(
        uint256 price_
    )
        external
        payable
        override
        validDeadLine
        validPrice(price_)
        onlyDepositor
        returns (bool isBuyOrder_)
    {
        require(msg.sender != address(0) && msg.value > 0, "invalid value");

        uint256 _amount = msg.value;

        _orderID = _orderID._add(1);
        _amount = _amount._dev(price_);

        isBuyOrder_ = _buyOrder(msg.sender, _getOrderID(), price_, _amount);
    }

    function _buyOrder(
        address buyer_,
        uint256 orderID_,
        uint256 price_,
        uint256 amount_
    ) internal returns (bool isBuyOrder_) {
        _orders[orderID_] = ORDER(buyer_, ORDERTYPE.BUY, price_, amount_);

        emit BuyOrderEvent(buyer_, orderID_, price_, amount_);

        isBuyOrder_ = true;
    }

    function sellOrder(
        uint256 price_,
        uint256 amount_
    )
        external
        override
        validDeadLine
        validPrice(price_)
        onlyDepositor
        returns (bool isSellOrder_)
    {
        require(_shares[msg.sender] >= amount_, "amount is high");

        _orderID = _orderID._add(1);

        isSellOrder_ = _sellOrder(msg.sender, _getOrderID(), price_, amount_);
    }

    function _sellOrder(
        address seller_,
        uint256 orderID_,
        uint256 price_,
        uint256 amount_
    ) internal returns (bool isSellOrder_) {
        _shares[seller_] -= _shares[seller_]._sub(amount_);

        _orders[orderID_] = ORDER(seller_, ORDERTYPE.SELL, price_, amount_);

        emit SellOrderEvent(seller_, orderID_, price_, amount_);

        isSellOrder_ = true;
    }

    function buyTrade(
        uint256 orderID_
    )
        external
        payable
        override
        validDeadLine
        onlyDepositor
        returns (bool isBuyTrade_)
    {
        require(orderID_ > 0 && msg.value > 0, "invalid value");
        ORDER storage _order = _orderOf(orderID_);

        require(msg.sender != _order._orderer, "caller is only buyer");
        require(_order._orderType == ORDERTYPE.SELL, "order is only SELL");
        require(msg.value <= _order._amount * _order._price, "value is high");
        require(_order._amount > 0, "amount is empty");

        uint256 _amount = msg.value;
        _amount = _amount._dev(_order._price);

        isBuyTrade_ = _buyTrade(_order, msg.sender, orderID_, _amount);
    }

    function _buyTrade(
        ORDER storage order_,
        address buyer_,
        uint256 orderID_,
        uint256 amount_
    ) internal returns (bool isBuyTrade_) {
        (uint256 _fee, uint256 _feeShares) = _genFeeAndFeeShares(
            amount_,
            order_._price
        );

        _shares[buyer_] = _shares[buyer_]._add(amount_._sub(_feeShares));
        _shares[_owner] = _shares[_owner]._add(_feeShares);

        _balances[order_._orderer] = _balances[order_._orderer]._add(
            (amount_ * order_._price) - _fee
        );

        _balances[order_._orderer] = _balances[order_._orderer]._add(_fee);

        order_._amount = order_._amount._sub(amount_);

        if (order_._amount == 0) delete _orders[orderID_];

        emit TradeMatchEvent(buyer_, order_._orderer, orderID_, amount_);

        isBuyTrade_ = true;
    }

    function cancelOrder(
        uint256 orderID_
    ) external override returns (bool isCancelOrder_) {
        ORDER storage _order = _orderOf(orderID_);
        require(msg.sender == _order._orderer, "caller is only orderer");

        isCancelOrder_ = _cancelOrder(msg.sender, orderID_, _order);
    }

    function _cancelOrder(
        address orderer_,
        uint256 orderID_,
        ORDER memory order_
    ) internal returns (bool isCancelOrder_) {
        if (order_._orderType == ORDERTYPE.BUY)
            _balances[orderer_] = _balances[orderer_]._add(
                order_._amount * order_._price
            );

        if (order_._orderType == ORDERTYPE.SELL)
            _shares[orderer_] = _shares[orderer_]._add(order_._amount);

        delete _orders[orderID_];

        emit CancelOrderEvent(orderer_, orderID_, order_._price, order_._price);

        isCancelOrder_ = true;
    }

    function sellTrade(
        uint256 orderID_,
        uint256 amount_
    )
        external
        override
        validDeadLine
        onlyDepositor
        returns (bool isSellTrade_)
    {
        require(orderID_ > 0 && amount_ > 0, "invalid value");
        ORDER storage _order = _orderOf(orderID_);

        require(msg.sender != _order._orderer, "caller is only seller");
        require(_order._orderType == ORDERTYPE.BUY, "order is only BUY");
        require(
            _order._amount >= amount_ && _shares[msg.sender] >= amount_,
            "amount is high"
        );
        require(_order._amount > 0, "amount is empty");

        isSellTrade_ = _sellTrade(_order, msg.sender, orderID_, amount_);
    }

    function _sellTrade(
        ORDER storage order_,
        address seller_,
        uint256 orderID_,
        uint256 amount_
    ) internal returns (bool isSellTrade_) {
        (uint256 _fee, uint256 _feeShares) = _genFeeAndFeeShares(
            amount_,
            order_._price
        );

        _shares[seller_] = _shares[seller_]._sub(amount_);
        _shares[order_._orderer] = _shares[order_._orderer]._add(
            amount_._sub(_feeShares)
        );
        _shares[_owner] = _shares[_owner]._add(_fee);

        order_._amount = order_._amount._sub(amount_);

        if (order_._amount == 0) delete _orders[orderID_];

        emit TradeMatchEvent(order_._orderer, seller_, orderID_, amount_);

        isSellTrade_ = true;
    }

    /// Note. Oracle
    function resolvePredictionMarket(
        bool predictionResult_
    ) external onlyOwner returns (bool isPredictionResult_) {
        require(block.timestamp > _deadlineTime, "not yet deadline");
        require(
            _resultStatus == RESULTSTATUS.OPEN,
            "prediction status is only open"
        );

        isPredictionResult_ = _resolvePredictionMarket(
            msg.sender,
            predictionResult_
        );
    }

    function _resolvePredictionMarket(
        address owner_,
        bool predictionResult_
    ) internal returns (bool isPredictionResult_) {
        _resultStatus = predictionResult_ ? RESULTSTATUS.YES : RESULTSTATUS.NO;

        if (_resultStatus == RESULTSTATUS.NO)
            _balances[_owner] = _balances[_owner]._add(_collateral);

        emit ResolvePredictionMarketEvent(owner_, _resultStatus);

        isPredictionResult_ = true;
    }

    function withdraw() external returns (bool isWithdraw_) {
        uint256 _balance = _balances[msg.sender];
        require(_balance > 0, "balance is empty");

        _balances[msg.sender] = 0;

        if (_resultStatus == RESULTSTATUS.YES) {
            _balance = _balance._add(_shares[msg.sender] * 100);
            _shares[msg.sender] = 0;
        }

        (bool _isSend, ) = msg.sender.call{value: _balance}("");
        require(_isSend, "not send eth");

        isWithdraw_ = _isSend;
    }

    function _orderOf(
        uint256 orderID_
    ) internal view returns (ORDER storage order_) {
        order_ = _orders[orderID_];
    }

    function _genFeeAndFeeShares(
        uint256 amount_,
        uint256 price_
    ) internal pure returns (uint256 fee_, uint256 feeShares_) {
        fee_ = ((amount_ * price_) * TX_FEE_NUMERATOR) / TX_FEE_DENOMINATOR;
        feeShares_ = (amount_ * TX_FEE_NUMERATOR) / TX_FEE_DENOMINATOR;
    }

    function _getOrderID() internal view returns (uint256 orderID_) {
        orderID_ = _orderID;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "caller is only owner");
        _;
    }

    modifier onlyDepositor() {
        require(msg.sender != _owner, "caller is only depositor");
        _;
    }

    modifier validDeadLine() {
        require(block.timestamp < _deadlineTime, "deadline is over");
        _;
    }

    modifier validPrice(uint256 price_) {
        require(price_ > 0 && price_ <= 100, "from 0 to 100 price");
        _;
    }
}
