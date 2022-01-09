// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lender {

    address payable contractOwner;
    uint contractId;
    uint rate;
    mapping(uint => Loan) idToLoan;
    mapping(address => uint[]) clientToLoansIds;
    uint[] requestIds;

    constructor() payable {
        contractOwner = payable(msg.sender);
        contractId = 0;
        rate = 10;
    }

    modifier isBankManager() {
        require(msg.sender == contractOwner);
        _;
    }

    function deposite() public payable isBankManager {
    }

    function getBalance() public view isBankManager returns (uint) {
        return address(this).balance;
    }

    function retrieve() public isBankManager {
        contractOwner.transfer(address(this).balance);
    }

    enum LoanStatus {
        REQUESTED,
        GRANTED,
        DENIED,
        PAID_BACK
    }

    struct Loan {
        uint id;
        address payable borrowerAddress;
        uint amountBorrowed;
        uint amountLeftToBePaid;
        uint rate;
        LoanStatus state;
    }

    function requestLoan(uint _amount) public {
        Loan memory newLoan = Loan(contractId, payable(msg.sender), _amount, _amount * rate / 100, rate, LoanStatus.REQUESTED);
        
        idToLoan[contractId] = newLoan;
        clientToLoansIds[msg.sender].push(contractId);
        requestIds.push(contractId);

        contractId++;
    }

    function getRequestedLoans() public view isBankManager returns (Loan[] memory) {
        Loan[] memory requestedLoans = new Loan[](requestIds.length);

        for (uint i=0; i<requestIds.length; i++) {
            requestedLoans[i] = idToLoan[requestIds[i]];
        }

        return requestedLoans;
    }

    function getUserLoans() public view isBankManager returns (Loan[] memory) {
        Loan[] memory userLoans = new Loan[](clientToLoansIds[msg.sender].length);

        for (uint i=0; i<clientToLoansIds[msg.sender].length; i++) {
            userLoans[i] = idToLoan[clientToLoansIds[msg.sender][i]];
        }

        return userLoans;
    }

    function deleteLoanFromRequestedLoans(uint _loanId) private isBankManager {
        for (uint i=0; i<requestIds.length; i++) {
            if (requestIds[i] == _loanId) {
                requestIds[i] = requestIds[requestIds.length-1];
                requestIds.pop();
                break;
            }
        }
    }

    function grantLoan(uint _loanId) public isBankManager {
        require(idToLoan[_loanId].amountBorrowed <= address(this).balance);

        idToLoan[_loanId].borrowerAddress.transfer(idToLoan[_loanId].amountBorrowed);
        idToLoan[_loanId].state = LoanStatus.GRANTED;

        deleteLoanFromRequestedLoans(_loanId);
    }

    function denyLoan(uint _loanId) public isBankManager {
        idToLoan[_loanId].state = LoanStatus.DENIED;
        
        deleteLoanFromRequestedLoans(_loanId);
    }

    function payBackLoan(uint _loanId) public payable {
        require(idToLoan[_loanId].state == LoanStatus.GRANTED);
        require(msg.sender == idToLoan[_loanId].borrowerAddress);
        require(msg.value == idToLoan[_loanId].amountBorrowed + idToLoan[_loanId].amountLeftToBePaid);

        idToLoan[_loanId].state = LoanStatus.PAID_BACK;
    }
}
