// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface IAdmin {
    function isAdmin(address user) external view returns (bool);
}