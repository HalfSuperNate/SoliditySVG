// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Base64} from "solady/src/utils/Base64.sol";
import {LibPRNG} from "solady/src/utils/LibPRNG.sol";
import {LibString} from "solady/src/utils/LibString.sol";

/*
SVG Examples & Info:

    0,0 = top left
    250,250 = bottom right
    0,250 = bottom left
    250,0 = top right

    <svg height="250" width="250" style="background:#25252560;">
        //yellow triangle filling bottom left half of the canvas
        // Layer 0
        <polygon points="0,0 250,250 0,250" stroke="black" stroke-width="1" fill="#FFBF00"/>

        //centered red circle that fills the canvas with a black stroke outside
        // Layer 1
        <circle cx="125" cy="125" r="125" stroke="black" stroke-width="3" fill="red" />

        //centered lightgrey ellipse that is inside the red circle
        // Layer 2
        <ellipse cx="125" cy="125" rx="100" ry="50" stroke="purple" stroke-width="2" fill="lightgrey"/>

        //positioned red rectangle
        // Layer 3
        <rect x="100" y="100" width="25" height="100" stroke="rgb(0,0,0)" stroke-width="2" fill="rgb(255,0,25)" />

        //positioned line
        // Layer 4
        <line x1="10" y1="0" x2="210" y2="200" stroke-width="1" stroke="rgb(55,100,25)" />

        //positioned polyline
        // Layer 5
        <polyline points="20,20 40,25 60,40 80,120 120,140 200,180" stroke="rgb(0,0,0)" stroke-width="2" fill="none" />

        Sorry, your browser does not support inline SVG.
    </svg>

*/

contract SVG {
    using LibPRNG for LibPRNG.PRNG;
    using LibString for uint256;
    using LibString for int256;
    using LibString for string;
    using Base64 for string;

    string constant __ = " "; // whitespace
    string constant stroke = "stroke=";
    string constant strokeWidth = "stroke-width=";
    string constant fill = "fill=";
    string constant _startElement = "<";
    string constant _endElement = "/>";
    string constant _dq = '"';

    struct _SVG {
        uint256 size;
        string background;
        string[] elements;
    }

    //too deep here
    function createSVG(_SVG memory svg) public pure returns (string memory) {
        string memory elements = "";
        for (uint256 i = 0; i < svg.elements.length; i++) {
            elements = string(abi.encodePacked(elements, svg.elements[i]));
        }

        return string(abi.encodePacked(
            "<svg height=", _dq, svg.size.toString(), _dq,
            " width=", _dq, svg.size.toString(), _dq,
            " style=", _dq, svg.background, _dq,
            ">", elements, "</svg>"
        ));
    }

    function createElement(string memory elementType, string memory attributes) internal pure returns (string memory) {
        return string(abi.encodePacked(_startElement, elementType, __, attributes, __, _endElement));
    }

    /**
    @dev Returns a random number in the range of min and max.
    @param _seed The random user input number.
    @param _min The min random result.
    @param _max The max random result.
    @return A random selected number within the inclusive range.
    */
    function getRandom(uint _seed, uint _min, uint _max) public view returns (uint256){
        uint random = uint(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            msg.sender,
            _seed,
            _min,
            _max,
            isEvenTimestamp())
        )) % 100;

        LibPRNG.PRNG memory newPRNG = LibPRNG.PRNG({
            state: random
        });
        uint _newPRNG = LibPRNG.uniform(newPRNG,101);

        uint _dif = (_max - _min);
        uint _calcRandom = ((_dif * _newPRNG) / 100);

        return _min + _calcRandom;
    }

    function isEvenTimestamp() public view returns (bool) {
        return block.timestamp % 2 == 0;
    }
}
