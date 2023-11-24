// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

/*
SVG Examples & Info:

    0,0 = top left
    250,250 = bottom right
    0,250 = bottom left
    250,0 = top right

    <svg height="250" width="250" style="background:#25252560;">
        //yellow triangle filling bottom left half of the canvas
        // Layer 0
        <polygon points="0,0 250,250 0,250" style="fill:#FFBF00;stroke:black;stroke-width:1" />

        //centered red circle that fills the canvas with a black stroke outside
        // Layer 1
        <circle cx="125" cy="125" r="125" stroke="black" stroke-width="3" fill="red" />

        Sorry, your browser does not support inline SVG.
    </svg>

*/

contract SVG {}