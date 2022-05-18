// Used by:
// Card 3076 using item sillystring

package game.data.specialAbility.store
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Salute;
	import game.data.specialAbility.SpecialAbility;
	import game.data.specialAbility.SpecialAbilityData;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;

	/**
	 * Spray silly string from canister 
	 */
	public class SillyString extends SpecialAbility
	{
		private var stringActive:Boolean;
		private var string1:Shape;
		private var string2:Shape;
		private var pointData1:Array;
		private var pointData2:Array;
		private var pointCount:Number;
		private var span:Number;
		private var color1:uint = 0x41FFD4;
		private var color2:uint = 0xFF5BFF;
		private var wait:Number = 4;
		private var xPos:Number;
		private var yPos:Number;
		private var dirNum:Number = 1;
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				var _parentEntity:Entity = node.entity
				CharUtils.setAnim( node.entity, Salute );
				CharUtils.getTimeline( node.entity ).handleLabel( Animation.LABEL_ENDING, onAnimEnd);
				CharUtils.getTimeline( node.entity ).handleLabel( "raised", doString);
				CharUtils.lockControls( node.entity, true );
				super.setActive( true );
			}
		}
		
		private function doString():void
		{
			// call any now actions
			actionCall(SpecialAbilityData.NOW_ACTIONS_ID);

			CharUtils.getTimeline( super.entity ).stop();
			stringActive = true;
			
			// Get the X and Y values
			var handspatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charspatial:Spatial = super.entity.get(Spatial);
			xPos = charspatial.x - (handspatial.x * charspatial.scale) + 14;
			yPos = charspatial.y + (handspatial.y * charspatial.scale) - 11;
			
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				xPos = charspatial.x + (handspatial.x * charspatial.scale) - 14;
				dirNum = -1;
			} else {
				dirNum = 1;
			}
			
			// Create the strings
			pointCount = 20;
			span = 0;
			
			// Make the point data arrays
			pointData1 = new Array();
			pointData2 = new Array();
			
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			string1 = new Shape();
			container.addChild(string1);
			string2 = new Shape();
			container.addChild(string2);
		}
		
		private function onAnimEnd():void
		{
			// revert to previous animation
			CharUtils.stateDrivenOn( super.entity );
			CharUtils.lockControls( super.entity, false, false );
			
			super.setActive( false );
		}
		
		override public function update(node:SpecialAbilityNode, time:Number):void
		{
			if(stringActive)
			{
				wait++;
				if (wait > 4)
				{
					wait = 0;
					span ++;
					pointCount --;
					if (pointCount < 1) {
						stringActive = false;
						var container:DisplayObjectContainer = node.entity.get(Display).container;
						container.removeChild(string1);
						container.removeChild(string2);
						CharUtils.getTimeline( node.entity ).play();
					}
					
					// Make a new point and point data
					var pointData:Object = new Object();
					var pt:Point = new Point(xPos, yPos);
					pointData.point = pt;
					pointData.velX = dirNum * (Math.random()*5 + 5);
					pointData.velY = Math.random()*5 - 5;
					pointData.accelY = 0.2;
					pointData.life = 100;
					pointData1.push(pointData);
					
					var pData2:Object = new Object();
					var pt2:Point = new Point(xPos, yPos);
					pData2.point = pt2;
					pData2.velX = dirNum * (Math.random()*5 + 5);
					pData2.velY = Math.random()*5 - 5;
					pData2.accelY = 0.2;
					pData2.life = 100;
					pointData2.push(pData2);
				}
				
				// Dynamically draw the string through the points
				string1.graphics.clear();
				string1.graphics.lineStyle(2, color1, 1, false, "normal", "none");
				string1.graphics.moveTo(xPos, yPos);
				var lineAlpha:Number = 1;
				
				// String 1 update
				for (var i:Number = 0; i < pointData1.length-1; i++) {
					var curPt:Object = pointData1[i];
					var nextPt:Object = pointData1[i + 1];
					
					var midX:Number = (curPt.point.x + nextPt.point.x)/2;
					var midY:Number = (curPt.point.y + nextPt.point.y)/2;
					string1.graphics.curveTo(curPt.point.x, curPt.point.y, midX, midY);
					lineAlpha -= .4;
					string1.graphics.lineStyle(2, color1, lineAlpha, false, "normal", "none");						
					curPt.velY += curPt.accelY;
					curPt.point = curPt.point.add(new Point(curPt.velX, curPt.velY));
					curPt.life -= 3;
					if (curPt.life <= 0) {
						pointData1.splice(i, 1);
					}
				}
				
				string2.graphics.clear();
				string2.graphics.lineStyle(2, color2, 1, false, "normal", "none");
				string2.graphics.moveTo(xPos, yPos);
				var lineAlpha2:Number = 1;
				
				// String 2 update
				for (var j:Number = 0; j < pointData2.length-1; j++) {
					var curPt2:Object = pointData2[j];
					var nextPt2:Object = pointData2[j + 1];
					
					var midX2:Number = (curPt2.point.x + nextPt2.point.x)/2;
					var midY2:Number = (curPt2.point.y + nextPt2.point.y)/2;
					string2.graphics.curveTo(curPt2.point.x, curPt2.point.y, midX2, midY2);
					lineAlpha -= .4;
					string2.graphics.lineStyle(2, color2, lineAlpha2, false, "normal", "none");						
					curPt2.velY += curPt2.accelY;
					curPt2.point = curPt2.point.add(new Point(curPt2.velX, curPt2.velY));
					curPt2.life -= 3;
					if (curPt2.life <= 0) {
						pointData2.splice(j, 1);
					}
				}
			}
		}
	}
}