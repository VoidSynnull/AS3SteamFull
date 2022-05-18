package game.scenes.poptropolis.weightLift.systems 
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.scenes.poptropolis.weightLift.WeightLift;
	import game.scenes.poptropolis.weightLift.nodes.TargetNode;
	import game.systems.SystemPriorities;
	
	public class TargetSystem extends System
	{
		private var _targets:NodeList;
		private var centerX:Number = -18;
		private var centerY:Number = 103;
		private var radiusX:Number = 252;
		private var radiusY:Number = 252;
		private var angle:Number = -3.2;
		
		private var easing:Boolean = false;
		private var easeIn:Boolean = false;
		
		private var target:TargetNode;
		private var spatial:Spatial;
		private var speedVariable:Number;
		private var speedVariable2:Number;
		
		public function TargetSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_targets = systemManager.getNodeList( TargetNode );
			target = _targets.head;
			spatial = target.entity.get(Spatial);
			speedVariable = target.target.speedVariable;
			speedVariable2 = target.target.speedVariable2;
		}
		
		override public function update( time:Number ):void
		{				
			spatial.x = centerX + Math.sin(angle) * radiusX;
			spatial.y = centerY + Math.cos(angle) * radiusY;
			var dx:Number = centerX - spatial.x;
			var dy:Number = centerY - spatial.y;
			var radians:Number = Math.atan2(dy, dx);
			spatial.rotation = radians * 180 / Math.PI;
			var t:MovieClip = target.display.displayObject as MovieClip;
			t.swirl.rotation -= 8;
			if(target.target.lifting){
				target.target.counter--;
				if(target.target.counter < 0){
					WeightLift(super.group).gameOver();
				}
				if(Math.ceil(target.target.counter / 60) < 10){
					super.group["counterText"].text = "0"+Math.ceil(target.target.counter / 60);
					if(Math.ceil(target.target.counter / 60) != target.target.countSound){
						WeightLift(super.group).playSound("countdown");
						target.target.countSound = Math.ceil(target.target.counter / 60);
					}
				}else{
					super.group["counterText"].text = Math.ceil(target.target.counter / 60);
				}
				
				//wait for drop
				target.target.waitForDrop++;
				if(target.target.waitForDrop > 90){
					WeightLift(super.group).dropFromWait();
					target.target.waitForDrop = 0;
				}
			}
			
			if(angle > -2){
				angle = -2;
				target.target.speed *= -1;
				easing = false;
				easeIn = false;
				target.target.speedEase = 0;
			}
			if(angle < -4.2){
				angle = -4.2;
				target.target.speed *= -1;
				easing = false;
				easeIn = false;
				target.target.speedEase = 0;
			}
			if(!easing){
				if(target.target.counter%speedVariable2 == 0){
					easing = true;
					easeIn = true;
					//speed *= -1;
					speedVariable2 = randRange(speedVariable-(speedVariable/2), speedVariable+(speedVariable/2));
				}
				
			}else{
				if(easeIn){
					if(target.target.speed > 0){
						if(target.target.speed - target.target.speedEase > 0){
							target.target.speedEase += .004;
						}else{
							easeIn = false;
							target.target.speed *= -1;
						}
					}else{
						if(target.target.speed - target.target.speedEase < 0){
							target.target.speedEase -= .004;
						}else{
							easeIn = false;
							target.target.speed *= -1;
						}
					}
				}else{
					if(target.target.speed < 0){
						if(target.target.speedEase > 0){
							target.target.speedEase -= .004;
						}else{
							easing = false;
							easeIn = true;
						}
					}else{
						if(target.target.speedEase < 0){
							target.target.speedEase += .004;
						}else{
							easing = false;
							easeIn = true;
						}
					}
				}
			}
			angle += target.target.speed - target.target.speedEase;
			
			//show bonus
			if(target.target.showBonus){
				if(target.target.currWeight < target.target.finalScore){
					target.target.currWeight++;
					super.group["sb"]["score"].text = "Score = "+target.target.currWeight;
					
				}else{
					target.target.showBonus = false;
					WeightLift(super.group).hideCongrats();
				}
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( TargetNode );
			_targets = null;
		}
		
		private function randRange(min:Number, max:Number):Number {
			var randomNum:Number = Math.floor(Math.random()*(max-min+1))+min;
				return randomNum;
		}
	}
}