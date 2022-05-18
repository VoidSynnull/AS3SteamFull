package game.scenes.timmy.zoo.systems 
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.character.Skin;
	import game.scenes.timmy.zoo.Zoo;
	import game.scenes.timmy.zoo.nodes.BallNode;
	import game.systems.SystemPriorities;
	import game.util.DisplayUtils;
	
	public class BeachballSystem extends System
	{
		private var _balls:NodeList;
		private var ball:BallNode;
		private var ballSpatial:Spatial;
		private var ballDisplay:Display;
		private var playerSpatial:Spatial;
		private var hand:Entity;
		private var handSpatial:Spatial;
		private var mX:Number;
		private var mY:Number;
		private var dx:Number;
		private var dy:Number;
		private var mouseContainer:DisplayObject;
		
		private var r1:Number = 34;
		private var r2:Number = 34;
		private var r3:Number = 54;
		private var gravity:Number = 0.6;
		private var dampX:Number = 0.995;
		private var dampY:Number = 0.997;
		private var limitRight:Number = 2183;
		private var limitLeft:Number = 1476;
		private var ground:Number = 1108;
		private var ground2:Number = 1150;
		private var gameOver:Boolean = false;
		
		private var distFromRight:Number = 0;
		private var distFromLeft:Number = 0;
		private var ratio:Number;
		private var force:Number = .5;
		
		private var bearX:Number = 1683;
		private var bearY:Number = 1104;
		private var enteredGoal:Boolean = false;
		private var handPoint:Point;
		
		//private var previousPlayerX:Number = 0;
		
		public function BeachballSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_balls = systemManager.getNodeList( BallNode );
			ball = _balls.head;
			
			ballSpatial = ball.entity.get(Spatial);
			ballDisplay = ball.entity.get(Display);
			playerSpatial = Zoo(super.group).player.get(Spatial);
			mouseContainer = Zoo(super.group).player.get(Display).container;
			
			hand = Skin( Zoo(super.group).player.get( Skin )).getSkinPartEntity( "hand1" );
			handSpatial = hand.get(Spatial);
		}
		
		override public function update( time:Number ):void
		{
			if(ball.ball.playing){
				moveBall();
			}
			if(Zoo(super.group).inPolePosition) {
				movePole();
			}
		}
		
		private function movePole():void {
			mX = mouseContainer.mouseX;
			mY = mouseContainer.mouseY;
			handPoint = DisplayUtils.localToLocal(hand.get(Display).displayObject, mouseContainer);
			dx = mX - handPoint.x;
			dy = mY - handPoint.y;
			
			if(playerSpatial.scaleX < 0) {
				handSpatial.rotation = -(Math.atan2(dy, dx) * 180 / Math.PI);
			} else {
				handSpatial.rotation = (Math.atan2(dy, dx) * 180 / Math.PI) - 180;
			}
		}
		
		private function moveBall():void {
			ball.ball.vy += gravity;
			ball.ball.vx *= dampX;
			
			ball.ball.vy *= dampY;
			ballSpatial.x += ball.ball.vx;
			ballSpatial.y += ball.ball.vy;
			
			//bounce on walls
			if(!enteredGoal) {
				if (ballSpatial.x > limitRight - r2) {
					ballSpatial.x = limitRight - r2;
					ball.ball.vx *= -1;
					//Zoo(super.group).playBallSound();
				} else if (ballSpatial.x < limitLeft + r2) {
					if(ballSpatial.y < 729) {
						enteredGoal = true;
					}else{
						ballSpatial.x = limitLeft + r2;
						ball.ball.vx *= -1;
						//Zoo(super.group).playBallSound();
					}
				}
			} else {
				var dx:Number;
				var dy:Number;
				var dist:Number;
				dx = ballSpatial.x - playerSpatial.x;
				dy = ballSpatial.y - playerSpatial.y;
				dist = Math.sqrt(dx*dx + dy*dy);
				if(dist < r2 * 2){
					Zoo(super.group).endBallGame();
				}
				if(ballSpatial.y > 729) {
					Zoo(super.group).endBallGame();
				}
			}
			
			//bounce on floor
			if (ballSpatial.x > 1758) {
				if (ballSpatial.y > ground - r2) {
					ballSpatial.y = ground - r2;
					ball.ball.vy *= -1;
					//Zoo(super.group).playBallSound();
				}
			} else if(ballSpatial.x > (bearX - 80) && ballSpatial.x < (bearX + 80)){
				if (ballSpatial.y > ground - r2) {
					ballSpatial.y = ground - r2;
					ball.ball.vy = -25;
					Zoo(super.group).hitBall();
				}
			} else {
				if (ballSpatial.y > ground2 - r2) {
					ballSpatial.y = ground2 - r2;
					ball.ball.vy *= -.7;
					//ball.ball.vy = -25;
					//Zoo(super.group).playBallSound();
				}
			}
			
			//fans
			distFromRight = limitRight - ballSpatial.x;
			distFromLeft = ballSpatial.x - limitLeft;
			
			if(distFromRight < 400){
				ratio = 1 - (distFromRight / 400);
				ball.ball.vx -= force * ratio;
			} else if(Zoo(super.group).leftFanSpinning) {
				if(distFromLeft < 400){
					ratio = 1 - (distFromLeft / 400);
					ball.ball.vx += force * ratio;
				}
			} else {
				if(Math.abs(ball.ball.vx) < 1){
					if(ball.ball.vx >= 0) {
						//ball.ball.vx = 1;
					} else {
						//ball.ball.vx = -1;
					}
				}
			}
			
			ballSpatial.rotation += ball.ball.vx;
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( BallNode );
			_balls = null;
		}
	}
}




