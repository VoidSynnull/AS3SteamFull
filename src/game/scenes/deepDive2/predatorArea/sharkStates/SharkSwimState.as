package game.scenes.deepDive2.predatorArea.sharkStates
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	public class SharkSwimState extends SharkState
	{
		public function SharkSwimState()
		{
			super.type = "swim";
		}
		
		override public function start():void
		{
			this.init();
			
			this.sharkTimeline.gotoAndPlay("slow");
			this.finTimeline.gotoAndPlay("slow");
			this.tailTimeline.gotoAndPlay("slow");
			
			this.node.motion.maxVelocity = new Point(300,300);
			this.node.motion.friction = new Point(100,100);
		}
		
		override public function update(time:Number):void
		{
			checkTarget();
			if(node.shark.swimPoint){
				accelToSwim();
			} else {
				node.motion.zeroAcceleration();
				node.motion.zeroMotion();
				node.fsmControl.setState("idle");
			}
			
			if(node.motion.velocity.x > 250 || node.motion.velocity.y > 250){
				if(!swimmingFast){
					this.sharkTimeline.gotoAndPlay("fast");
					this.finTimeline.gotoAndPlay("fast");
					this.tailTimeline.gotoAndPlay("fast");
					swimmingFast = true;
				}
			} else {
				if(swimmingFast){
					this.sharkTimeline.gotoAndPlay("slow");
					this.finTimeline.gotoAndPlay("slow");
					this.tailTimeline.gotoAndPlay("slow");
					swimmingFast = false;
				}
			}
			
			orientShark();
		}
		
		private function accelToSwim():void{
			
			var origin:Point = new Point(node.spatial.x, node.spatial.y);
			var dY:Number = node.shark.swimPoint.y - origin.y;
			var dX:Number = node.shark.swimPoint.x - origin.x;
			
			var angle:Number = Math.atan2(dY, dX);
			var accelPoint:Point = new Point(swimSpeed*Math.cos(angle),swimSpeed*Math.sin(angle));
			node.motion.acceleration = accelPoint;
			
			var faceAngle:Number = Math.atan2(node.motion.velocity.y, node.motion.velocity.x);
			
			if(node.motion.velocity.y > 0 || node.motion.velocity.x > 0){
				node.spatial.rotation = faceAngle * (180/Math.PI); // rotate shark to anglular velocity
			}
			
		}
		
		private function checkTarget():void{
			if(node.shark.targetEntity){
				var targetSpatial:Spatial = node.shark.targetEntity.get(Spatial);
				var targetPoint:Point = new Point(targetSpatial.x, targetSpatial.y);
				var sharkPoint:Point = new Point(node.spatial.x, node.spatial.y);
				
				node.shark.swimPoint = targetPoint;
				
				// check if within attack distance
				/*if(Point.distance(sharkPoint,targetPoint) <= attackDistance){
					// attack target
					node.shark.swimPoint = null;
					node.shark.attackPoint = targetPoint;
					node.fsmControl.setState("attack");
				} else {
					// stalk target
					node.shark.swimPoint = targetPoint;
				}*/
				
			} else {
				node.shark.swimPoint = null;
			}
		}
		
		private var swimSpeed:Number = 400;
		private var swimmingFast:Boolean = false;
		private var attackDistance:Number = 350;
	}
}