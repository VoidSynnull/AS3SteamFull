// Used by:
// Card 3126 using items photdogshooter1, photdogshooter2
// Card 3127 using items photdogshooter3, photdogshooter4

package game.data.specialAbility.character
{	
	import flash.display.DisplayObjectContainer;
	import flash.display.Shape;
	import flash.geom.Point;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Salute;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.util.CharUtils;
	
	/**
	 * Draw colored squirt effect from item
	 * 
	 * optional params
	 * color 		Uint		Color of squirt (default is red)
	 */
	public class Ketchup extends SpecialAbility
	{
		override public function activate( node:SpecialAbilityNode ):void
		{
			if ( !super.data.isActive )
			{
				CharUtils.setAnim( super.entity, Salute );
				CharUtils.getTimeline( super.entity ).handleLabel( Animation.LABEL_ENDING, onAnimEnd);
				CharUtils.getTimeline( super.entity ).handleLabel( "raised", doSquirt);
				CharUtils.lockControls( super.entity, true );
				super.setActive( true );
			}
		}
		
		/**
		 * Trigger squirt effect 
		 */
		private function doSquirt():void
		{
			CharUtils.getTimeline( super.entity ).stop();
			stringActive = true;
			
			// Get the X and Y values
			var handspatial:Spatial = CharUtils.getJoint(super.entity, CharUtils.HAND_FRONT).get(Spatial);
			var charspatial:Spatial = super.entity.get(Spatial);
			xPos = charspatial.x - (handspatial.x * charspatial.scale) + 26;
			yPos = charspatial.y + (handspatial.y * charspatial.scale) - 17;
			
			// Check to see which direction the character is facing
			var direction:String = super.entity.get(Spatial).scaleX > 0 ? CharUtils.DIRECTION_LEFT : CharUtils.DIRECTION_RIGHT;
			
			// Flip the object if you're facing Left
			if (direction == CharUtils.DIRECTION_LEFT)
			{
				xPos = charspatial.x + (handspatial.x * charspatial.scale) - 26;
				dirNum = -1;
			} else {
				dirNum = 1;
			}
			
			// Create the strings
			pointCount = 30;
			span = 0;
			
			// Make the point data arrays
			pointData1 = new Array();
			
			var container:DisplayObjectContainer = super.entity.get(Display).container;
			string1 = new Shape();
			container.addChild(string1);
		}
		
		/**
		 * When salute animation ends 
		 */
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
				if (wait > 1.4)
				{
					wait = 0;
					span ++;
					pointCount --;
					if (pointCount < 1) {
						stringActive = false;
						var container:DisplayObjectContainer = super.entity.get(Display).container;
						container.removeChild(string1);
						CharUtils.getTimeline( super.entity ).play();
					}
					
					// Make a new point and point data
					var pointData:Object = new Object();
					var pt:Point = new Point(xPos, yPos);
					pointData.point = pt;
					pointData.velX = dirNum * (Math.random()*5+3);
					pointData.velY = Math.random()*2-5;
					pointData.accelY = 0.2;
					pointData.life = 100;
					pointData1.push(pointData);
				}
				
				// Dynamically draw the string through the points
				string1.graphics.clear();
				string1.graphics.lineStyle(2, _color, 1, false, "normal", "none");
				string1.graphics.moveTo(xPos, yPos);
				var lineAlpha:Number = 1;
				
				// String 1 update
				for (var i:Number = 0; i < pointData1.length-1; i++) {
					var curPt:Object = pointData1[i];
					var nextPt:Object = pointData1[i + 1];
					
					var midX:Number = (curPt.point.x + nextPt.point.x)/2;
					var midY:Number = (curPt.point.y + nextPt.point.y)/2;
					string1.graphics.curveTo(curPt.point.x, curPt.point.y, midX, midY);
					lineAlpha -= .3;
					string1.graphics.lineStyle(2, _color, lineAlpha, false, "normal", "none");						
					curPt.velY += curPt.accelY;
					curPt.point = curPt.point.add(new Point(curPt.velX, curPt.velY));
					curPt.life -= 1.05;
					if (curPt.life <= 0) {
						pointData1 = pointData1.splice(i, 1);
					}
				}
			}
		}
		
		public var _color:uint = 0xFF0000;
		
		private var stringActive:Boolean;
		private var string1:Shape;
		private var pointData1:Array;
		private var pointCount:Number;
		private var span:Number;
		private var wait:Number = 4;
		private var xPos:Number;
		private var yPos:Number;
		private var dirNum:Number = 1;
	}
}