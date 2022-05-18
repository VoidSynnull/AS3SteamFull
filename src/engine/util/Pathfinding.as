/*************************************************************************
Pathfinding

Author : Billy Belfield
Date : 11/1/07

This class finds the path between two points (the START and the END point)
on a given map, taken into account walls/obstacles and terrain costs.
It uses an A* ("a star") algorithm with heuristic approximation for a faster
result. Much of this function is basic on theory learnt from this language
independent tutorial:

http://www.policyalmanac.org/games/aStarTutorial.htm

based on as 1.0 code by zeh : http://proto.layer51.com/d.aspx?f=998

*************************************************************************

Usage:

var pathfinder:Pathfinding = new Pathfinding();
var path = pathfinder.findPath(map, start_y, start_x, end_y, end_x);

map = A 2d array of integers.  Zero corresponds to a 'wall', and numbers greater than zero represent walkable nodes where the
      greater the number, the higher the cost of the path.  Numbers other than zero can also correspond to nodes with
	  special behaviors.
start_y/_x = starting row and column of the 2d map.
end_y/_x =   ending row and column of the 2d map. 

Note that the path returned is an array with the directions reversed (designed so that each new node along a path can be popped
off the array.

*/
package engine.util
{
	public class Pathfinding 
	{
		// "Movement cost" for horizontal/vertical moves
		private var _linearMovementCost:Number = 10;
		// "Movement cost" for diagonal moves
		private var _diagonalMovementCost:Number = 14;
		// If diagonal movements are allowed at all
		private var _allowDiagonalMovment:Boolean = true;
		// If diagonal movements over corners are allowed
		private var _allowDiagonalCornering:Boolean = true;
		// Contains the map and all the open and closed nodes on it.
		private var _mapStatus:Array;
		// Current open nodes
		private var _openList:Array;
		
		public function Pathfinding(linearMovementCost:Number = 10, diagonalMovementCost:Number = 14, allowDiagonalMovment:Boolean = true, allowDiagonalCornering:Boolean = true) 
		{
			_linearMovementCost = linearMovementCost;
			_diagonalMovementCost = diagonalMovementCost;
			_allowDiagonalMovment = allowDiagonalMovment;
			_allowDiagonalCornering = allowDiagonalCornering;
		}
		
		// Finds the way given a certain path
		public function findPathInternal(nodeMap:Array, startY:Number, startX:Number, endY:Number, endX:Number):Array 
		{
			// Ok, now go back to our regular schedule. Find the path! -------------------------
			// Caches dimensions
			var mapH:Number = nodeMap.length;
			var mapW:Number = nodeMap[0].length;
			var nowY:Number;
			var nowX:Number
			// New status arrays
			_mapStatus = new Array();
			for(var n:Number = 0; n<mapH; n++) 
			{
				_mapStatus[n] = new Array();
			}
			// Now really starts
			_openList = new Array();
			// ADDED 0, false params WRB
			openSquare(startY, startX, undefined, 0, 0, false);
			// Loops until there's no other way to go OR found the exit
			while(_openList.length>0 && !isClosed(endY, endX)) 
			{
				// Browse through open squares
				var i:Number = nearerSquare();
				nowY = Number(_openList[i][0]);
				nowX = Number(_openList[i][1]);
				// Closes current square as it has done its purpose...
				closeSquare(nowY, nowX);
				// Opens all nearby squares, ONLY if:
				for (var j:Number = nowY-1; j<nowY+2; j++) 
				{
					for (var k:Number = nowX-1; k<nowX+2; k++) 
					{
						if (j>=0 && j<mapH && k>=0 
							&& k<mapW && !(j == nowY && k == nowX) 
							&& (_allowDiagonalMovment || j == nowY || k == nowX) 
							&& (_allowDiagonalCornering || j == nowY || k == nowX || (nodeMap[j][nowX] != 0 
								&& nodeMap[nowY][k]))) {
							// If not outside the boundaries or at the same point or a diagonal (if disabled) or a diagonal (with a wall next to it)...
							if (nodeMap[j][k] != 0) {
								// And if not a wall...
								if (!isClosed(j, k)) {
									// And if not closed... THEN open.
									var movementCost:Number = _mapStatus[nowY][nowX].movementCost+((j == nowY || k == nowX ? _linearMovementCost : _diagonalMovementCost)*nodeMap[j][k]);
									if (isOpen(j, k)) {
										// Already opened: check if it's ok to re-open (cheaper)
										if (movementCost<_mapStatus[j][k].movementCost) {
											// Cheaper: simply replaces with new cost and parent.
											openSquare(j, k, [nowY, nowX], movementCost, undefined, true);
											// heuristic not passed: faster, not needed 'cause it's already set
										}
									} else {
										// Empty: open.
										var heuristic:Number = (Math.abs(j-endY)+Math.abs(k-endX))*10;
										openSquare(j, k, [nowY, nowX], movementCost, heuristic, false);
									}
								} else {
									// Already closed, ignore.
								}
							} else {
								// Wall, ignore.
							}
						}
					}
				}
			}
			// Ended
			var pFound:Boolean = isClosed(endY, endX);
			// Was the path found?
			if (pFound) {
				// Ended with path found; generates return path
				var returnPath:Array = new Array();
				nowY = endY;
				nowX = endX;
				while ((nowY != startY || nowX != startX)) {
					returnPath.push([nowY, nowX]);
					var newY:Number = _mapStatus[nowY][nowX].parent[0];
					var newX:Number = _mapStatus[nowY][nowX].parent[1];
					nowY = newY;
					nowX = newX;
				}
				returnPath.push([startY, startX]);
				// First START, last END			
				return (returnPath);
			} else {
				// Ended with 0 open squares; ran out of squares, path NOT found
				return null;
			}
		}
		
		private function isOpen(y:Number, x:Number):Boolean
		{
			// Return TRUE if the point is on the open list, false if otherwise
			if(_mapStatus[y][x] != undefined)
			{
				return _mapStatus[y][x].open;
			}
			return false;
		}
		
		private function isClosed(y:Number, x:Number):Boolean
		{
			// Return TRUE if the point is on the closed list, false if otherwise
			if(_mapStatus[y][x] != undefined)
			{
				return _mapStatus[y][x].closed;
			}
			return false;
		}
		
		private function nearerSquare():Number
		{
			// Returns the square with a lower movementCost + heuristic distance
			// from the open list
			var minimum:Number = 999999;
			var indexFound:Number = 0;
			var thisF:Number = undefined;
			var thisSquare:Object = undefined;
			var i:Number = _openList.length;
			// Finds lowest
			while (i-->0) 
			{
				thisSquare = _mapStatus[_openList[i][0]][_openList[i][1]];
				thisF = thisSquare.heuristic+thisSquare.movementCost;
				if (thisF<=minimum) 
				{
					minimum = thisF;
					indexFound = i;
				}
			}
			// Returns lowest
			return indexFound;
		}
		
		private function closeSquare(y:Number, x:Number):void
		{
			// Drop from the open list
			var len:Number = _openList.length;
			for (var i:Number = 0; i<len; i++) 
			{
				if (_openList[i][0] == y)
				{
					if (_openList[i][1] == x) 
					{
						_openList.splice(i, 1);
						break;
					}
				}
			}
			// Closes an open square
			_mapStatus[y][x].open = false;
			_mapStatus[y][x].closed = true;
		}
		
		private function openSquare(y:Number, x:Number, parent:Array, movementCost:Number, heuristic:Number, replacing:Boolean):void
		{
			// Opens a square
			if (!replacing) 
			{
				_openList.push([y, x]);
				_mapStatus[y][x] = {heuristic:heuristic, open:true, closed:false};
			}
			_mapStatus[y][x].parent = parent;
			_mapStatus[y][x].movementCost = movementCost;
		}
	}
}