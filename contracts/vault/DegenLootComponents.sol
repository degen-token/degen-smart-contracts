/**
 *Submitted for verification at Etherscan.io on 2021-08-30
 */

// SPDX-License-Identifier: Unlicense

/*

    LootComponents.sol
    
    This is a utility contract to make it easier for other
    contracts to work with Loot properties.
    
    Call weaponComponents(), chestComponents(), etc. to get 
    an array of attributes that correspond to the item. 
    
    The return format is:
    
    uint256[5] =>
        [0] = Item ID
        [1] = Suffix ID (0 for none)
        [2] = Name Prefix ID (0 for none)
        [3] = Name Suffix ID (0 for none)
        [4] = Augmentation (0 = false, 1 = true)
    
    See the item and attribute tables below for corresponding IDs.

*/

pragma solidity ^0.8.4;

contract LootComponents {
    string[] private weapons = [
        "Walking Cane",     // 0
        "Sword Cane",       // 1
        "Parasol",          // 2
        "Riding Crop",      // 3
        "Opera Glasses",    // 4
        "Lorgnette",        // 5
        "Spyglass",         // 6
        "Fountain Pen",     // 7
        "Pipe",             // 8
        "Snuff Box",        // 9
        "Pocket Watch",     // 10
        "Card Case",        // 11
        "Rifle"             // 12
        "Dueling Pistol",   // 13
        "Fan",              // 14
        "Gizmo",            // 15
        "Broadsheet",       // 16
        "Prayer Book",      // 17
    ];

    string[] private chestArmor = [
        "Shirt",                // 0
        "Linen Shirt",          // 1
        "Silk Shirt",           // 2
        "Morning Coat",         // 3
        "Velvet Tailcoat",      // 4
        "Tweed Jacket",         // 5
        "Embroidered Jacket",   // 6
        "Frock Coat",           // 7
        "Wool Overcoat",        // 8
        "Whalebone Corset",     // 9
        "Brocade Bodice",       // 10
        "Evening Gown",         // 11
        "Day Dress",            // 12
        "Ball Gown",            // 13
        "Shawl"                 // 14
    ];

    string[] private headArmor = [
        "Top Hat",      // 0
        "Bowler Hat",   // 1
        "Trilby",       // 2
        "Deerstalker",  // 3
        "Straw Hat",    // 4
        "Turban",       // 5
        "Cowl",         // 6
        "Skull Cap",    // 7
        "Pith Helmet"   // 8
        "Monocle",      // 9
        "Pince-nez",    // 10
        "Lace Cap",     // 11
        "Bonnet",       // 12
        "Fascinator",   // 13
        "Veil",         // 14
    ];

    string[] private waistArmor = [
        "Forager Belt",     // 0
        "Ornate Belt",      // 1
        "Pleated Belt",     // 2
        "Mesh Belt",        // 3
        "Bustle",           // 4
        "Leopard Hide",     // 5
        "Sword Belt",       // 6
        "Crocodile Belt",   // 7
        "Cowhide Belt",     // 8
        "Cumberbund",       // 9
        "Lifting Belt",     // 10
        "Silk Sash",        // 11
        "Wool Sash",        // 12
        "Linen Sash",       // 13
        "Sash"              // 14
    ];

    string[] private footArmor = [
        "Loafers",          // 0
        "Brogues",          // 1
        "Oxfords",          // 2
        "Monkstraps",       // 3
        "Riding Boots",     // 4
        "Combat Boots",     // 5
        "Buckskin Boots",   // 6
        "Pilgrim Boots",    // 7
        "Crocodile Boots",  // 8
        "Cowhide Boots",    // 9
        "Glass Slippers",   // 10
        "Silk Slippers",    // 11
        "Wool Slippers",    // 12
        "Linen Slippers",   // 13
        "Slippers"          // 14
    ];

    string[] private handArmor = [
        "Smudged Fingers", // 0
        "Ornate Gloves", // 1
        "Gauntlets", // 2
        "Claws", // 3
        "Boxing Gloves", // 4
        "Bear Hands", // 5
        "Fencing Gloves", // 6
        "Bangles", // 7
        "Crocodile Gloves", // 8
        "Cowhide Gloves", // 9
        "Velvet Gloves", // 10
        "Silk Gloves", // 11
        "Wool Gloves", // 12
        "Linen Gloves", // 13
        "Gloves" // 14
    ];

    string[] private necklaces = [
        "Necklace", // 0
        "Amulet", // 1
        "Pendant" // 2
    ];

    string[] private rings = [
        "Gold Ring", // 0
        "Silver Ring", // 1
        "Bronze Ring", // 2
        "Platinum Ring", // 3
        "Titanium Ring" // 4
    ];

    string[] private suffixes = [
        // <no suffix>          // 0
        "of Power", // 1
        "of Giants", // 2
        "of Titans", // 3
        "of Skill", // 4
        "of Perfection", // 5
        "of Brilliance", // 6
        "of Enlightenment", // 7
        "of Protection", // 8
        "of Anger", // 9
        "of Rage", // 10
        "of Fury", // 11
        "of Vitriol", // 12
        "of the Fox", // 13
        "of Detection", // 14
        "of Reflection", // 15
        "of the Twins" // 16
    ];

    string[] private namePrefixes = [
        // <no name>            // 0
        "Agony", // 1
        "Apocalypse", // 2
        "Armageddon", // 3
        "Beast", // 4
        "Behemoth", // 5
        "Blight", // 6
        "Blood", // 7
        "Bramble", // 8
        "Brimstone", // 9
        "Brood", // 10
        "Carrion", // 11
        "Cataclysm", // 12
        "Chimeric", // 13
        "Corpse", // 14
        "Corruption", // 15
        "Damnation", // 16
        "Death", // 17
        "Demon", // 18
        "Dire", // 19
        "Dragon", // 20
        "Dread", // 21
        "Doom", // 22
        "Dusk", // 23
        "Eagle", // 24
        "Empyrean", // 25
        "Fate", // 26
        "Foe", // 27
        "Gale", // 28
        "Ghoul", // 29
        "Gloom", // 30
        "Glyph", // 31
        "Golem", // 32
        "Grim", // 33
        "Hate", // 34
        "Havoc", // 35
        "Honour", // 36
        "Horror", // 37
        "Hypnotic", // 38
        "Kraken", // 39
        "Loath", // 40
        "Maelstrom", // 41
        "Mind", // 42
        "Miracle", // 43
        "Morbid", // 44
        "Oblivion", // 45
        "Onslaught", // 46
        "Pain", // 47
        "Pandemonium", // 48
        "Phoenix", // 49
        "Plague", // 50
        "Rage", // 51
        "Rapture", // 52
        "Rune", // 53
        "Skull", // 54
        "Sol", // 55
        "Soul", // 56
        "Sorrow", // 57
        "Spirit", // 58
        "Storm", // 59
        "Tempest", // 60
        "Torment", // 61
        "Vengeance", // 62
        "Victory", // 63
        "Viper", // 64
        "Vortex", // 65
        "Woe", // 66
        "Wrath", // 67
        "Light's", // 68
        "Shimmering" // 69
    ];

    string[] private nameSuffixes = [
        // <no name>            // 0
        "Bane", // 1
        "Root", // 2
        "Bite", // 3
        "Song", // 4
        "Roar", // 5
        "Grasp", // 6
        "Instrument", // 7
        "Glow", // 8
        "Bender", // 9
        "Shadow", // 10
        "Whisper", // 11
        "Shout", // 12
        "Growl", // 13
        "Tear", // 14
        "Peak", // 15
        "Form", // 16
        "Sun", // 17
        "Moon" // 18
    ];

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function weaponComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "WEAPON", weapons);
    }

    function chestComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "CHEST", chestArmor);
    }

    function headComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "HEAD", headArmor);
    }

    function waistComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "WAIST", waistArmor);
    }

    function footComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "FOOT", footArmor);
    }

    function handComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "HAND", handArmor);
    }

    function neckComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "NECK", necklaces);
    }

    function ringComponents(
        uint256 tokenId
    ) public view returns (uint256[5] memory) {
        return pluck(tokenId, "RING", rings);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string[] memory sourceArray
    ) internal view returns (uint256[5] memory) {
        uint256[5] memory components;

        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, toString(tokenId)))
        );

        components[0] = rand % sourceArray.length;
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = rand % 21;
        if (greatness > 14) {
            components[1] = (rand % suffixes.length) + 1;
        }
        if (greatness >= 19) {
            components[2] = (rand % namePrefixes.length) + 1;
            components[3] = (rand % nameSuffixes.length) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }
        return components;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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
}
