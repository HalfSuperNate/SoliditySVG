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

contract SVGPlotter {
    using LibPRNG for LibPRNG.PRNG;
    using LibString for uint256;
    using LibString for int256;
    using LibString for string;
    using Base64 for string;

    string constant __ = " "; // whitespace
    string constant stroke = '" stroke="';
    string constant strokeWidth = ' stroke-width="';
    string constant fill = ' fill="';
    string constant _startElement = "<";
    string constant _endElement = " />";
    string constant _dq = '"';
    string constant none = '"none"';
    string constant height = ' height="';
    string constant width = ' width="';
    string constant background = ' style="background:#';
    string constant _endStyle = ';"';
    string constant _startGroup = '<g';
    string constant _endGroup = '</g>';
    string constant _n = "-"; // negative


    struct SVG {
        uint256[2] heightWidth;
        uint256[4] backgroundColor;
        string[] elements;
    }

    struct StrokeFill {
        uint256 strokeWidth;
        uint256[4] stroke;
        uint256[4][2] randomizeStroke; // if [0,0] ignore
        uint256[4] fill;
        uint256[4][2] randomizeFill; // if [0,0] ignore
    }

    struct ElementData {
        uint256 decimals; // number of decimal points for floats
        /*
            polygon = uses at least 3 points where 1st and last point is connected
            circle = uses 2 points, 1st point is center position, 2nd is radius x = y
            ellipse = uses 2 points, 1st point is center position, 2nd is radius x & radius y
            rect = uses 2 points, 1st is top left corner position, 2nd is width & height from 1st point
            line = uses 2 points, 1st is start position, 2nd is end position
            polyline = uses at least 3 points
            path = uses points and letter commands to create a complex line or shape
        */
        string elementType;
        // point position(s)
        int256[] x;
        int256[][2] randomizeX; // if [0,0] ignore
        int256[] y;
        int256[][2] randomizeY; // if [0,0] ignore
        /*
            Path Command Notes:
                Capital = absolute position
                lowercase = relative position
            Path Commands:
                M = moveto
                L = lineto
                H = horizontal lineto
                V = vertical lineto
                C = curveto
                S = smooth curveto
                Q = quadratic Bézier curve
                T = smooth quadratic Bézier curveto
                A = elliptical Arc
                Z = closepath
        */
        string[] pathCommands;

        // inline transform and stroke/fill can be added when element is created
    }

    struct Transform {
        bool useDefault; // default transform="translate(0, 0) rotate(0) scale(1)"
        int256[2] position;
        int256[3] rotation;
        int256 scale;
        uint256[4][2] randomizeXYRS; // if [0,0] ignore
    }

    function createSVG(SVG memory svg) public pure returns (string memory) {
        string memory elements = "";
        for (uint256 i = 0; i < svg.elements.length; i++) {
            elements = string(abi.encodePacked(elements, svg.elements[i]));
        }

        return string(abi.encodePacked(
            setSVG(svg), elements, "Sorry, your browser does not support inline SVG.</svg>"
        ));
    }

    function setSVG(SVG memory svg) public pure returns (string memory) {
        return string.concat(
            "<svg", 
            getHeightWidth(svg.heightWidth[0],svg.heightWidth[1]),
            getBackground(svg.backgroundColor), _endStyle,
            ">"
        );
    }

    //❌ working on this
    function createElement(ElementData memory _elementData, StrokeFill memory _strokeFill, Transform memory _transform) internal pure returns (string memory) {
        string memory attributes;
        // Data
        // Stroke & Fill
        if(_strokeFill.strokeWidth != 0 && _strokeFill.stroke[3] != 0) {
            attributes = string(abi.encodePacked(attributes, stroke, strokeWidth, fill));
        } else{
            //transparent or no stroke
            attributes = string(abi.encodePacked(attributes, stroke, strokeWidth, fill));
        }
        if(_strokeFill.fill[3] != 0) {
            attributes = string(abi.encodePacked(attributes, stroke, strokeWidth, fill));
        } else{
            //transparent or no fill
            attributes = string(abi.encodePacked(attributes, stroke, strokeWidth, fill));
        }
        
        // Inline Transform
        if(!_transform.useDefault) {
            attributes = string(abi.encodePacked(attributes, ' transform="translate(', _transform.position[0],",", _transform.position[1],' rotate(', _transform.rotation[0], ",",  _transform.rotation[1], ",",  _transform.rotation[2], ') scale(',  _transform.scale, ')"' ));
        } else{
            //use nothing to default to transform="translate(0, 0) rotate(0) scale(1)"
        }
        return string(abi.encodePacked(_startElement, _elementData.elementType, __, attributes, __, _endElement));
    }

    function getHeightWidth(uint256 _height, uint256 _width) public pure returns (string memory) {
        return string.concat(
            height, _height.toString(), _dq,
            width, _width.toString(), _dq
        );
    }

    function getBackground(uint256[4] memory _color) public pure returns (string memory) {
        return string.concat(
            background,
            uintToColorHex(false, _color[0], _color[1], _color[2], _color[3])
        );
    }

    /**
    @dev Returns a random number in the range of min and max.
    @param _seed The random user input number.
    @param _min The min random result.
    @param _max The max random result.
    @return A random selected number within the inclusive range.
    */
    function getRandom(uint _seed, int _min, int _max) public view returns (int256){
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
        int _newPRNG = int(LibPRNG.uniform(newPRNG,101));

        int _dif = (_max - _min);
        int _calcRandom = ((_dif * _newPRNG) / 100);

        return _min + _calcRandom;
    }

    function isEvenTimestamp() public view returns (bool) {
        return block.timestamp % 2 == 0;
    }

    // Color & Alpha/Opacity
    // 4 Channels (Red, Green, Blue, Alpha)
    // Each channel is equal to a uint slider 0 - 255
    // If Alpha channel is omitted color will default to full Alpha
    // 255 = ff (full channel)

    function uintToColorHex(bool prependHash, uint256 red, uint256 green, uint256 blue, uint256 alpha) public pure returns (string memory) {
        string memory _alpha = "";
        if (!compareHexStrings(bytes(toHexString(alpha)), bytes("ff"))) {
            // set alpha if not full
            _alpha = toHexString(alpha);
        }
        
        if(prependHash){
            return string(abi.encodePacked("#", toHexString(red), toHexString(green), toHexString(blue), _alpha));
        } else{
            return string(abi.encodePacked(toHexString(red), toHexString(green), toHexString(blue), _alpha));
        }
    } 

    function uintToHex(uint256 number) public pure returns (string memory) {
        // Convert uint to hexadecimal string
        return toHexString(number);
    }

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "00";  // Special case for zero
        }
        
        uint256 temp = value;
        uint256 length = 0;
        
        while (temp > 0) {
            length++;
            temp /= 16;
        }

        // Ensure even length
        if (length % 2 != 0) {
            length++;
        }

        bytes memory buffer = new bytes(length);
        while (value > 0) {
            length--;
            uint8 remainder = uint8(value % 16);
            bytes1 byteValue = toAsciiChar(remainder);
            buffer[length] = byteValue;
            value /= 16;
        }

        // Prepend "0" if the length is one
        if (length == 1) {
            return string(abi.encodePacked("0", buffer));
        } else {
            return string(buffer);
        }
    }

    function toAsciiChar(uint8 value) internal pure returns (bytes1) {
        if (value < 10) {
            return bytes1(uint8(48 + value));
        } else {
            return bytes1(uint8(87 + value)); // ASCII for 'a' is 97, so 87 + 10 = 97
        }
    }

    function compareHexStrings(bytes memory a, bytes memory b) internal pure returns (bool) {
        if (a.length != b.length) {
            return false;
        }

        for (uint i = 0; i < a.length; i++) {
            if (a[i] != b[i]) {
                return false;
            }
        }

        return true;
    }

    // Number to Float
    function intToFloat(int256 number, uint256 decimals) external pure returns (string memory) {
        require(decimals <= 18, "Decimals too large");
        bool isNegative = number < 0;
        uint256 absoluteValue = isNegative ? uint256(-number) : uint256(number);

        uint256 divisor = 10**decimals;
        uint256 prefix = absoluteValue / divisor;
        uint256 suffix = absoluteValue % divisor;

        string memory result = toFloat(prefix, suffix, decimals);

        if (isNegative) {
            result = string(abi.encodePacked("-", result));
        }

        return result;
    }

    function toFloat(uint256 prefix, uint256 suffix, uint256 decimals) public pure returns (string memory) {
        string memory result = string(abi.encodePacked(uintToString(prefix)));

        if (decimals > 0) {
            result = string(abi.encodePacked(result, ".", padWithZeros(uintToString(suffix), decimals)));
        }

        return result;
    }

    function uintToString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function padWithZeros(string memory input, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(length);
        bytes memory inputBytes = bytes(input);

        uint256 i = 0;
        while (i < length - inputBytes.length) {
            buffer[i] = '0';
            i++;
        }

        for (uint256 j = 0; j < inputBytes.length; j++) {
            buffer[i] = inputBytes[j];
            i++;
        }

        return string(buffer);
    }
}
