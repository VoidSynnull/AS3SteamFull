package game.scenes.poptropolis.volleyball.systems 
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.animation.RigAnimation;
	import game.scenes.poptropolis.volleyball.Volleyball;
	import game.scenes.poptropolis.volleyball.nodes.BallNode;
	import game.systems.SystemPriorities;
	
	public class VolleyballSystem extends System
	{
		private var _balls:NodeList;
		private var ball:BallNode;
		private var ballSpatial:Spatial;
		private var ballDisplay:Display;
		private var playerSpatial:Spatial;
		private var playerDisplay:Display;
		private var playerTimeline:Timeline;
		private var netDisplay:Display;
		private var t1Spatial:Spatial;
		private var t2Spatial:Spatial;
		private var t1botSpatial:Spatial;
		private var t2botSpatial:Spatial;
		private var panTargetSpatial:Spatial;
		private var score1Timeline:Timeline;
		private var score2Timeline:Timeline;
		private var scoreboardTimeline:Timeline;
		private var sb:MovieClip;
		private var mX:Number;
		private var mY:Number;
		private var mouseContainer:DisplayObject;
		
		private var r1:Number = 35;
		private var r2:Number = 35;
		private var r3:Number = 55;
		private var gravity:Number = 0.6;
		private var damp:Number = .98;
		private var w:Number = 2000;
		private var oppVx:Number = 3;
		private var oppVx2:Number = 1;
		private var ground:Number = 800;
		private var playerScore:Number = 0;
		private var oppScore:Number = 0;
		private var goal:Number = 6;
		private var playerSide:Boolean = true;
		private var gameOver:Boolean = false;
		private var ballRotMod:Number = -2;
		private var ballUnderNet:Boolean = false;
		
		private var previousPlayerX:Number = 0;
				
		public function VolleyballSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_balls = systemManager.getNodeList( BallNode );
			ball = _balls.head;
			ballSpatial = ball.entity.get(Spatial);
			ballDisplay = ball.entity.get(Display);
			playerSpatial = Volleyball(super.group).player.get(Spatial);
			playerDisplay = Volleyball(super.group).player.get(Display);
			playerTimeline = Volleyball(super.group).player.get(Timeline);
			netDisplay = Volleyball(super.group).net.get(Display);
			t1Spatial = Volleyball(super.group).t1.get(Spatial);
			t1botSpatial = Volleyball(super.group).t1bot.get(Spatial);
			t2Spatial = Volleyball(super.group).t2.get(Spatial);
			t2botSpatial = Volleyball(super.group).t2bot.get(Spatial);
			panTargetSpatial = Volleyball(super.group).panTarget.get(Spatial);
			score1Timeline = Volleyball(super.group).score1.get(Timeline);
			score2Timeline = Volleyball(super.group).score2.get(Timeline);
			scoreboardTimeline = Volleyball(super.group).scoreboard.get(Timeline);
			sb = MovieClip(Volleyball(super.group).scoreboard.get(Display).displayObject);
			mouseContainer = Volleyball(super.group).player.get(Display).container;
		}
		
		override public function update( time:Number ):void
		{
			mX = mouseContainer.mouseX;
			mY = mouseContainer.mouseY;
			movePlayers();
			
			if(ball.ball.playing){
				moveBall();
				checkHit();
			}
			
			if(sb["flip1"].visible){
				sb["flip1"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num1"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num2"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num3"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num4"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num5"].gotoAndStop(sb.currentFrame);
				sb["flip1"]["num6"].gotoAndStop(sb.currentFrame);
			}
			if(sb["flip2"].visible){
				sb["flip2"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num1"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num2"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num3"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num4"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num5"].gotoAndStop(sb.currentFrame);
				sb["flip2"]["num6"].gotoAndStop(sb.currentFrame);
			}
			
		}
		
		private function movePlayers():void
		{
			var vx:Number;
			if(panTargetSpatial.x < 1050){
				vx = (mX - playerSpatial.x) / 12;
				
			}else{
				vx = (mX - playerSpatial.x) / 100;
				//Volleyball(super.group).stand();
				//playerSpatial.x += (mX - playerSpatial.x) / 100;
			}
			playerSpatial.x += vx;
			if(Math.abs(vx) > 7){
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'run'){
					Volleyball(super.group).run();
				}
			}else if(Math.abs(vx) > .5 && Math.abs(vx) <=7){
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'walk'){
					Volleyball(super.group).walk();
				}
			}else{
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'stand'){
					Volleyball(super.group).stand();
				}
			}
			
			if(vx > 0){
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'score'){
					playerTimeline.reverse = false;
				}
			}else if(vx < 0){
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'score'){
					playerTimeline.reverse = true;
				}
			}
			if(playerSpatial.x < 262){
				playerSpatial.x = 262;
			}
			if(playerSpatial.x > 996){
				playerSpatial.x = 996;
			}
			if(Math.abs(playerSpatial.x - previousPlayerX) <= .5){
				playerSpatial.x = previousPlayerX;
				if(Volleyball(super.group).player.get(RigAnimation).current.data.name != 'stand'){
					Volleyball(super.group).stand();
				}
			}
			//if(Volleyball(super.group).player.get(RigAnimation).current.data.name == 'stand'){
				//Volleyball(super.group).walk();
			//}
			
			if(!playerSide && ballDisplay.visible){
				//move tentacle 1
				if(t1Spatial.x > ballSpatial.x + 60){
					t1Spatial.x -= oppVx;
				}else if(t1Spatial.x < ballSpatial.x + 30){
					t1Spatial.x += oppVx;
				}
				
				if(t1Spatial.x <= 1000){
					t1Spatial.x = 1000;
				}
				if(t1Spatial.x >= 1400){
					t1Spatial.x = 1400;
				}
				t1botSpatial.x = t1Spatial.x + 47;
				t2botSpatial.x = t2Spatial.x + 56;
				
				//move tentacle 2
				if(t2Spatial.x > ballSpatial.x + 60){
					t2Spatial.x -= oppVx2;
				}else if(t2Spatial.x < ballSpatial.x + 30){
					t2Spatial.x += oppVx2;
				}
				
				if(t2Spatial.x <= 1300){
					t2Spatial.x = 1300;
				}
				if(t2Spatial.x >= 1700){
					t2Spatial.x = 1700;
				}
				
			}
			
			panTargetSpatial.x += (ballSpatial.x - panTargetSpatial.x) * .2;
			previousPlayerX = playerSpatial.x;
		}
		
		private function moveBall():void
		{
			ball.ball.vy += gravity;
			ball.ball.vx *= damp;
			if(ball.ball.vx == 0){
				ball.ball.vx = 1;
			}
			ball.ball.vy *= damp;
			ballSpatial.x += ball.ball.vx;
			ballSpatial.y += ball.ball.vy;
			
			if (ballSpatial.x > w - r2) {
				ballSpatial.x = w - r2;
				ball.ball.vx *= -1;
				Volleyball(super.group).playBallSound();
			} else if (ballSpatial.x < r2) {
				ballSpatial.x = r2;
				ball.ball.vx *= -1;
				Volleyball(super.group).playBallSound();
			}
			//check hit net
			if(ballSpatial.x > 930 && ballSpatial.x < 950){
				if(ballSpatial.y > 540 && ballSpatial.y < 680){
					if(ball.ball.vx > 0){
						ballSpatial.x = 930;
						ball.ball.vx *= -1;
					}else{
						ballSpatial.x = 950;
						ball.ball.vx *= -1;
					}
				}else if(ballSpatial.y >= 680){
					ballUnderNet = true;
					trace("Ball Under Net");
				}
				
			}
			
			if(!gameOver && ballSpatial.y > ground + 100) {
				ball.ball.playing = false;
				ballDisplay.visible = false;
				if(ballUnderNet){
					if(playerSide){
						playerScore++;
						Volleyball(super.group).showScore(true, playerScore);
						//score1Timeline.gotoAndStop(playerScore);
					}else{
						oppScore++;
						Volleyball(super.group).showScore(false, oppScore);
						//score2Timeline.gotoAndStop(oppScore);
					}		
				}else{
					if(playerSide){
						oppScore++;
						Volleyball(super.group).showScore(false, oppScore);
						//score2Timeline.gotoAndStop(oppScore);
					}else{
						playerScore++;
						Volleyball(super.group).showScore(true, playerScore);
						//score1Timeline.gotoAndStop(playerScore);
					}			
				}
					
				if(oppScore >= goal){
					trace("Game over");
					gameOver = true;
					ball.ball.playing = false;
					Volleyball(super.group).gameOver(playerScore, oppScore);
				}else if(playerScore >= goal){
					trace("Win Game");
					gameOver = true;
					ball.ball.playing = false;
					Volleyball(super.group).gameOver(playerScore, oppScore);
				}else{
					ballSpatial.x = t1Spatial.x;
					ballSpatial.y = 100;
					ball.ball.vx = 0;
					ball.ball.vy = 0;
					ballDisplay.visible = true;
					ballUnderNet = false;
				}
			}
			ballSpatial.rotation += ballRotMod;
			if(!playerSide){
				if(ballSpatial.x < 950){
					playerSide = true;
					if(ballDisplay.getIndex() < netDisplay.getIndex()){
						ballDisplay.displayObject.parent.addChild(ballDisplay.displayObject);
					}
					
					if(ballSpatial.y >= 680){
						ballUnderNet = true;
						trace("Ball Under Net");
					}
				}
			}else{
				if(ballSpatial.x >= 950){
					playerSide = false;
					if(ballDisplay.getIndex() > netDisplay.getIndex())
					{
						ballDisplay.displayObject.parent.addChild(netDisplay.displayObject);
						ballDisplay.displayObject.parent.addChild(playerDisplay.displayObject);
					}
					
					if(ballSpatial.y >= 680){
						ballUnderNet = true;
						trace("Ball Under Net");
					}
				}
			}			
		}
		
		private function checkHit():void
		{
			if(!ballUnderNet){
				var dx:Number;
				var dy:Number;
				var r:Number;
				var dx2:Number;
				var dy2:Number;
				var rad2:Number;
				var radians:Number;
				
				if(playerSide && ballSpatial.y < 800){
					dx = ballSpatial.x - playerSpatial.x;
					dy = ballSpatial.y - playerSpatial.y;
					r = Math.sqrt(dx*dx + dy*dy);
					
					if(r < r1+r2){
						radians = Math.atan(dy/dx);
						if(dx >= 0){
							radians += Math.PI;
						}
						
						ballSpatial.x = playerSpatial.x - (r1 + r2)*Math.cos(radians);
						ballSpatial.y = playerSpatial.y - (r1 + r2)*Math.sin(radians);
						ball.ball.vx = -33*Math.cos(radians);
						ball.ball.vy = -33*Math.sin(radians);
						
						ballRotMod = -2; 
						Volleyball(super.group).hitBall();
					}
				}else if(ballSpatial.y + r2 - 10 < 800){
					dx = ballSpatial.x - t1Spatial.x;
					dy = ballSpatial.y - t1Spatial.y;
					r = Math.sqrt(dx*dx + dy*dy);
					
					dx2 = ballSpatial.x - t2Spatial.x;
					dy2 = ballSpatial.y - t2Spatial.y;
					rad2 = Math.sqrt(dx2*dx2 + dy2*dy2);
					
					if(r < r1+r3){
						radians = Math.atan(dy/dx);
						if(dx >= 0){
							radians += Math.PI;
						}
						
						ballSpatial.x = t1Spatial.x - (r1 + r3)*Math.cos(radians);
						ballSpatial.y = t1Spatial.y - (r1 + r3)*Math.sin(radians);
						ball.ball.vx = -30*Math.cos(radians);
						ball.ball.vy = -30*Math.sin(radians);
						
						ballRotMod = 2; 
						Volleyball(super.group).t1HitBall();
					}else if(rad2 < r1+r3){
						radians = Math.atan(dy2/dx2);
						if(dx2 >= 0){
							radians += Math.PI;
						}
						
						ballSpatial.x = t2Spatial.x - (r1 + r3)*Math.cos(radians);
						ballSpatial.y = t2Spatial.y - (r1 + r3)*Math.sin(radians);
						ball.ball.vx = -30*Math.cos(radians);
						ball.ball.vy = -30*Math.sin(radians);
						
						ballRotMod = 2; 
						Volleyball(super.group).t2HitBall();
					}
				}
			}
		}		
		
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( BallNode );
			_balls = null;
		}
	}
}




