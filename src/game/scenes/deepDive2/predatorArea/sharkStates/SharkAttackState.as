package game.scenes.deepDive2.predatorArea.sharkStates
{
	import flash.geom.Point;
	
	import engine.components.Spatial;
	
	public class SharkAttackState extends SharkState
	{
		public function SharkAttackState()
		{
			super.type = "attack";
		}
		
		override public function start():void
		{
			this.init();
			
			this.sharkTimeline.gotoAndPlay("fast");
			this.finTimeline.gotoAndPlay("fast");
			this.tailTimeline.gotoAndPlay("fast");
			this.headTimeline.gotoAndPlay("open");
			
			if(node.shark.attackPoint){ // single attack
				_targetSpatial = null;
				this.node.motion.zeroAcceleration();
				this.node.motion.zeroMotion();
				
				if(node.shark.attackPoint != null){
					_attackPoint = node.shark.attackPoint;
					node.shark.attackPoint = null;
				}
			}
			
			if(node.shark.targetEntity){
				_targetSpatial = node.shark.targetEntity.get(Spatial);
				_attackPoint = new Point(_targetSpatial.x, _targetSpatial.y);
				this.node.motion.friction = new Point(1000,1000);
			}
			
			this.node.motion.maxVelocity = new Point(1000,1000);
			
			accelToAttack();
		}
		
		override public function update(time:Number):void
		{
			
			if(_targetSpatial){ // persue target on attack
				_attackPoint = new Point(_targetSpatial.x, _targetSpatial.y);
				accelToAttack();
			}
			
			var sharkPoint:Point =  new Point(node.spatial.x, node.spatial.y);

			if(!_targetSpatial){
				if(_attackPoint){
					if(Point.distance(sharkPoint, _attackPoint) < 60){
						chomp();
					}
				}
			} else {
				if(_attackPoint){
					if(Point.distance(sharkPoint, _attackPoint) < 140){
						chomp();
					}
				}
			}
				
			orientShark();
		}
		
		private function chomp():void{
			
			node.motion.zeroAcceleration();
			node.motion.zeroMotion();
			
			_attackPoint = null;
			_targetSpatial = null;
			
			//node.fsmControl.setState("idle");
			
			
			if(node.shark.targetEntity){
				
				if(node.shark.targetEntity != node.entity.group.getEntityById("player")){
					// destroy fish 
					this.headTimeline.gotoAndPlay("chompEat");
					node.entity.group.removeEntity(node.shark.targetEntity);
					node.fsmControl.setState("chew");
				} else {
					this.headTimeline.gotoAndPlay("chomp");
					node.fsmControl.setState("idle");
				}
				
				if(node.shark.foodFish.length > 0){
					// target next fish
					node.shark.targetEntity = node.shark.foodFish.pop();
				} else {
					// target player
					node.shark.targetEntity = node.entity.group.getEntityById("player");
				}
				
				
			} else {
				this.headTimeline.gotoAndPlay("chomp");
				node.fsmControl.setState("idle");
			}
			
			node.shark.bite.dispatch();	
		}
		
		private function accelToAttack():void{
			
			var origin:Point = new Point(node.spatial.x, node.spatial.y);
			var dY:Number = _attackPoint.y - origin.y;
			var dX:Number = _attackPoint.x - origin.x;
			
			var angle:Number = Math.atan2(dY, dX);
			var faceAngle:Number = Math.atan2(node.motion.velocity.y, node.motion.velocity.x);
			
			//node.spatial.rotation = angle * (180/Math.PI); // rotate shark to face target
			
			
			if(!_targetSpatial){
				node.spatial.rotation = angle * (180/Math.PI); // rotate shark to face target
			} else {
				node.spatial.rotation = faceAngle * (180/Math.PI); // rotate shark to anglular velocity
			}
			
			var accelPoint:Point = new Point(attackSpeed*Math.cos(angle),attackSpeed*Math.sin(angle));
			
			//node.motion.acceleration = accelPoint;
			node.motion.velocity = accelPoint;
		}
		
		private var _attackPoint:Point;
		private var _targetSpatial:Spatial;
		
		private const attackSpeed:Number = 800;
	}
}