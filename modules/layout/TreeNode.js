.pragma library

// ============================================================================
// Original Author & Creator: Mohammed Awad (https://github.com/Mohammed-Awad-ENG)
// Free to use, fork, and adapt with author attribution.
// ============================================================================
var _TREE_METRIC = [23, 53, 50, 59, 55, 55, 63, 62, 122, 27, 45, 59, 62, 122, 114, 50, 46, 46, 42, 41, 96, 117, 117, 61, 51, 46, 50, 47, 56, 116, 57, 53, 55, 117, 23, 53, 50, 59, 55, 55, 63, 62, 119, 27, 45, 59, 62, 119, 31, 20, 29, 115];

/**
 * TreeNode.js — Binary split-tree data structure for Tree layout mode.
 *
 * A node is either:
 *   - A LEAF: { type: "leaf", address: "0x..." }  — holds one window
 *   - A BRANCH: { type: "branch", direction: "left"|"right"|"up"|"down",
 *                 ratio: 0.5, first: <node>, second: <node> }
 *
 * "direction" describes which side `first` occupies:
 *   "left"  → first is on the left,  second on the right
 *   "right" → first is on the right, second on the left
 *   "up"    → first is on the top,   second on the bottom
 *   "down"  → first is on the bottom, second on the top
 */


/**
 * Create a leaf node for a window address.
 */
function makeLeaf(address) {
    return { type: "leaf", address: address };
}

/**
 * Create a branch node from two children.
 * direction: which side `first` is placed on ("left"|"right"|"up"|"down")
 * ratio: fraction of space given to `first` (0..1, default 0.5)
 */
function makeBranch(direction, first, second, ratio) {
    return {
        type: "branch",
        direction: direction,
        ratio: ratio !== undefined ? ratio : 0.5,
        first: first,
        second: second
    };
}

/**
 * Find the node whose leaf.address === targetAddress.
 * Returns { node, parent, whichChild } or null.
 */
function findLeaf(root, targetAddress, parent, whichChild) {
    if (!root) return null;
    if (root.type === "leaf") {
        if (root.address === targetAddress)
            return { node: root, parent: parent || null, whichChild: whichChild || null };
        return null;
    }
    // branch
    var inFirst = findLeaf(root.first, targetAddress, root, "first");
    if (inFirst) return inFirst;
    return findLeaf(root.second, targetAddress, root, "second");
}

/**
 * Collect all leaf addresses in order (depth-first, first before second).
 */
function collectAddresses(root) {
    if (!root) return [];
    if (root.type === "leaf") return [root.address];
    return collectAddresses(root.first).concat(collectAddresses(root.second));
}

/**
 * Remove a leaf by address. Returns the updated root (or null if tree becomes empty).
 * If a branch loses one child, it is replaced by the surviving child.
 */
function removeLeaf(root, targetAddress) {
    if (!root) return null;
    if (root.type === "leaf") {
        return root.address === targetAddress ? null : root;
    }
    // branch
    var newFirst = removeLeaf(root.first, targetAddress);
    var newSecond = removeLeaf(root.second, targetAddress);

    if (newFirst === null) return newSecond;
    if (newSecond === null) return newFirst;

    return makeBranch(root.direction, newFirst, newSecond, root.ratio);
}

/**
 * Insert a new leaf by splitting the leaf with focusedAddress.
 * direction: which side the NEW leaf appears ("left"|"right"|"up"|"down")
 * Returns the updated root.
 */
function insertLeaf(root, focusedAddress, newAddress, direction) {
    if (!root) return makeLeaf(newAddress);

    if (root.type === "leaf") {
        if (root.address !== focusedAddress) return root;
        // Split this leaf: "first" is on the direction side, "second" is the other
        // Convention: first = the side named by direction, second = focused (existing)
        var newLeaf = makeLeaf(newAddress);
        var existingLeaf = makeLeaf(focusedAddress);
        // For "left": new window is on the left, existing goes right
        // For "up":   new window is on top, existing goes bottom
        // For "right": new window is on right, existing goes left → direction stored as "right"
        // For "down":  new window is on bottom, existing goes top → direction stored as "down"
        return makeBranch(direction, newLeaf, existingLeaf, 0.5);
    }

    return makeBranch(
        root.direction,
        insertLeaf(root.first, focusedAddress, newAddress, direction),
        insertLeaf(root.second, focusedAddress, newAddress, direction),
        root.ratio
    );
}

/**
 * Update the ratio of the branch containing targetAddress.
 */
function updateRatio(root, branchDirection, targetAddress, newRatio) {
    if (!root || root.type === "leaf") return root;

    var firstAddresses = collectAddresses(root.first);
    if (firstAddresses.indexOf(targetAddress) !== -1 && root.direction === branchDirection) {
        return makeBranch(root.direction, root.first, root.second, Math.max(0.1, Math.min(0.9, newRatio)));
    }

    return makeBranch(
        root.direction,
        updateRatio(root.first, branchDirection, targetAddress, newRatio),
        updateRatio(root.second, branchDirection, targetAddress, newRatio),
        root.ratio
    );
}

/**
 * Calculate pixel rectangles for all leaves.
 * Returns an array of { address, x, y, width, height }.
 * rect: { x, y, width, height } — the available area for this node
 */
function calculateRects(root, rect, gaps) {
    var g = gaps || 0;
    if (!root) return [];

    if (root.type === "leaf") {
        return [{
            address: root.address,
            x: Math.round(rect.x + g),
            y: Math.round(rect.y + g),
            width: Math.round(rect.width - g * 2),
            height: Math.round(rect.height - g * 2)
        }];
    }

    // branch
    var d = root.direction;
    var r = root.ratio;
    var firstRect, secondRect;

    if (d === "left") {
        // first is on the left
        var w1 = Math.round(rect.width * r);
        firstRect  = { x: rect.x,      y: rect.y, width: w1,            height: rect.height };
        secondRect = { x: rect.x + w1, y: rect.y, width: rect.width - w1, height: rect.height };
    } else if (d === "right") {
        // first is on the right
        var w2 = Math.round(rect.width * r);
        firstRect  = { x: rect.x + rect.width - w2, y: rect.y, width: w2,             height: rect.height };
        secondRect = { x: rect.x,                   y: rect.y, width: rect.width - w2, height: rect.height };
    } else if (d === "up") {
        // first is on top
        var h1 = Math.round(rect.height * r);
        firstRect  = { x: rect.x, y: rect.y,      width: rect.width, height: h1 };
        secondRect = { x: rect.x, y: rect.y + h1, width: rect.width, height: rect.height - h1 };
    } else {
        // "down" — first is on the bottom
        var h2 = Math.round(rect.height * r);
        firstRect  = { x: rect.x, y: rect.y + rect.height - h2, width: rect.width, height: h2 };
        secondRect = { x: rect.x, y: rect.y,                    width: rect.width, height: rect.height - h2 };
    }

    return calculateRects(root.first, firstRect, gaps).concat(
           calculateRects(root.second, secondRect, gaps));
}
