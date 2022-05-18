package game.scenes.survival2.unfrozenLake
{
	
	import ash.core.Entity;
	import ash.core.System;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import game.data.scene.hit.MovingHitData;
	import flash.display.MovieClip;
	
	import game.components.entity.Sleep;
	import game.components.hit.EntityIdList;
	
	
	public class RaftMoverSystem extends System
	{
		public var _raft:Entity					//the raft
		public var _player:Entity				//the player
		public var _raftVelocity:Number;		//rafts x velocity
		public var _startY:Number;				//raft initial y position, for comparison to _curY
		public var _curY:Number;				//raft y postion, changes based on _onRaft
		public var _onRaft:Boolean = false; 	//currently on raft
		public var _hitRaft:Boolean = false; 	//initial land on raft	
		public var _count:Number = 0;  			//increment for raft y movement
		public var _raftRotation:Number;		//rafts rotation
		public var _startR:Number;				//raft initial rotation, for comparison to _curR
		public var _curR:Number;				//raft rotation, changes based on _onRaft
		public var _rotInc:Number;				//raft rotation increment
		public var _maxRot:Number;				//max raft rotation
		
		public const INITDAMP:Number = .7;  	//dampen x velocity on initial impact
		public const INC:Number = 60;  			//slow raft after initial impact divisor 		
		public const DAMP:Number = .6; 			//slow raft after initial impact dividend 
		public const MAXX:Number = 3343; 		//max x position raft can go
		public const MINX:Number = 1767; 		//min x position raft can go
		public const REBOUND:Number = 3; 		//x amount to move raft off of the max position
		public const STEP:Number = .05;  		//speed of rafts y movement
		public const RANGE:Number = 1.5; 		//range or rafts y movement
		public const RAFTDIST:Number = 10; 		//max number raft can sink with players weight  5
		public const DISTSTEP:Number = .5;		//speed at which raft sinks with players weight  .25
		
		public const RAFTDISTR:Number = 3; 		//max number raft can rotate with players weight
		public const DISTSTEPR:Number = .25;	//speed at which raft rotate with players weight
		public const RADIUS:Number = 240;  		//width between center and ends of raft 
		

		public function init (  __raft:Entity, __player:Entity):void{
			_raft = __raft;
			_player = __player;
			_startY = _curY = _raft.get(Spatial).y;		
			_startR = _curR = _raft.get(Spatial).rotation;	
			_rotInc = RADIUS/RAFTDISTR;
		}
		
		override public function update( time : Number ) : void{			

			if (_raft.get( Sleep ).sleeping == false){
			
				var motion:Motion = _player.get(Motion);
				var xVelocity:Number = motion.velocity.x * INITDAMP;
				var list:EntityIdList = _raft.get(EntityIdList);		
				
				if( list.entities.length > 0 ){
					_hitRaft = true; //flag true initial landing on raft					
				}else{
					_hitRaft = false; //flag false initial landing on raft
					_onRaft = false;  //flag player is off raft
				}
				
				if (_raft.get(Spatial).x > MAXX || _raft.get(Spatial).x < MINX){				
					_raftVelocity = 0;	//max position reached, stop raft x velocity					
				}else{
					if (_hitRaft == true && _onRaft == false ){
						_raftVelocity = xVelocity;  //set raft velocity to character velocity						
						_onRaft = true; //flag player is on raft
					}else{
						if (_raftVelocity < -3 || _raftVelocity > 3){	//using 3 here to stop the raft when it becomes very slow					
							_raftVelocity = _raftVelocity - (_raftVelocity * (DAMP/INC)); //decrease x velocity
						}else{						
							_raftVelocity = 0; //remove x velocity
						}
					}					
				}
				//update raft x velocity and rotation
				_raft.get(Motion).velocity.x = _raftVelocity;	
				_raft.get(Motion).rotation = _curR; 
				
				//move raft away from min or max edge
				if (_raft.get(Spatial).x > MAXX) _raft.get(Spatial).x = MAXX-REBOUND;
				if (_raft.get(Spatial).x < MINX) _raft.get(Spatial).x = MINX+REBOUND;
				
				_count += STEP; //increase increment by y speed
				_raft.get(Spatial).y = _curY + Math.sin(_count) * RANGE; //update raft y postion
				
				//sink or raise raft depending on whether or not player is on it
				if (_curY < _startY + RAFTDIST && _onRaft == true)_curY += DISTSTEP;				
				else if (_curY > _startY && _onRaft == false)_curY -= DISTSTEP;				
				
				//rotate the raft depending on whether or not the player is on it
				if (_onRaft == true){
					//maximum rotation based on distance from center of raft
					_maxRot = -((_raft.get(Spatial).x-_player.get(Spatial).x)/_rotInc);
					if (_maxRot < 0){ //player is to the left of center
						if (_curR > _maxRot) _curR -= DISTSTEPR;  //rotate raft down, have not reached max rotation
						if (_curR < _maxRot) _curR += DISTSTEPR;  //rotate raft back up, above max rotation
					}else{ //player is to the right of center
						if (_curR < _maxRot) _curR += DISTSTEPR;  //rotate raft down, have not reached max rotation
						if (_curR > _maxRot) _curR -= DISTSTEPR;  //rotate raft back up, above max rotation
					}
				}
				//not on raft, rotate raft back to start rotation
				else if (_curR < _startR && _onRaft == false)_curR += DISTSTEPR;
				else if (_curR > _startR && _onRaft == false)_curR -= DISTSTEPR;

			}
			
		}
	}
}