package game.scenes.myth.mountOlympus3.playerStates
{
	import engine.util.Command;
	
	import game.data.animation.Animation;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	
	public class CloudCharacterState extends FSMState
	{
		private var _timer:Number = 0;
		private const MAX_TIME:Number = .5;
		
		private const SPEED_MIN:int = 100;
		private const SPEED_MAX:int = 800;
		private const MIN_DIST:int = 60;
		private const MID_DIST:int = 120;
		private const MAX_DIST:int = 300;
		
		
		public static const ATTACK:String 				=	"cloudAttack";
		public static const STAND:String 				=	"cloudStand";
		public static const HURT:String 				=	"cloudHurt";
		public static const STATES:Vector.<String> 	= new <String>[ STAND, ATTACK, HURT ];
		
		//private var directionXFactor:Number = 0;
		//private var directionYFactor:Number = 0;
		
		public function CloudCharacterState()
		{
		}
		
		/**
		 * Use getter to cast node to CharacterStateNode.
		 */
		public function get node():CloudCharacterStateNode
		{
			return CloudCharacterStateNode(super._node);
		}
		
		///////////////////////// MOVEMENT /////////////////////////
		
		/**
		 * Update facing direction by velocity
		 * @param	node
		 * @return
		 */
		public function directionByVelocity():void
		{
			if ( node.motion.velocity.x > 0 )
			{
				node.spatial.scaleX = -node.spatial.scale;
			}
			else if( node.motion.velocity.x < 0 )
			{
				node.spatial.scaleX = node.spatial.scale;
			}
		}
		
		/**
		 * Method for moving character while in the air
		 * @param	node
		 */
		/*
		protected function move():void
		{
			var motionTarget:MotionTarget = node.motionTarget;

			if( node.motionControl.moveToTarget )// || PlatformUtils.isDesktop )
			{
				var spatial:Spatial = node.spatial;
				var motion:Motion = node.motion;

				motion.acceleration.x = motion.acceleration.y = 0;
				motion.friction.x = motion.friction.y = 0;
				motion.maxVelocity.x = motion.maxVelocity.x = this.SPEED_MIN + this.SPEED_MAX;
				
				var deltaDist:int = Math.sqrt( motionTarget.targetDeltaX * motionTarget.targetDeltaX + motionTarget.targetDeltaY * motionTarget.targetDeltaY )
				var radians:Number = GeomUtils.radiansBetween( motion.x, motion.y, motionTarget.targetX, motionTarget.targetY );
				
				var speed:Number;
				var speedFactor:Number;
				var distDiff:Number = deltaDist - this.MID_DIST;
				if( distDiff > 0 )
				{
					speedFactor = Math.min( distDiff/this.MAX_DIST, 1 )
					speed = this.SPEED_MIN + speedFactor * this.SPEED_MAX;
					motion.velocity.x = Math.cos( radians ) * speed;
					motion.velocity.y = Math.sin( radians ) * speed;
				}
				else if ( distDiff <= 0 )
				{
					speedFactor = 1 + Math.max( distDiff/this.MIN_DIST, -1 )
					speed = speedFactor * this.SPEED_MIN ;
					motion.velocity.x = Math.cos( radians ) * speed;
					motion.velocity.y = Math.sin( radians ) * speed;
				}
			}
			else
			{
				node.motion.velocity.y *= .95;
				node.motion.velocity.x *= .95;
			}
		}
		*/

		/*
		protected function moveFriction():void
		{
			
		}
		*/
		
		///////////////////////// ANIMATION /////////////////////////
		
		/**
		 * Set the animation
		 * @param	node
		 * @param	animClass
		 */
		protected function setAnim(animClass:Class, listendForEnd:Boolean = false ):void
		{	
			node.primary.next = animClass;
			if ( listendForEnd )
			{
				node.charMotionControl.animEnded = false;
				node.primary.ended.add( Command.create( onEnd, animClass ) );
			}
		}
		
		/**
		 * Handler for when animation ends, sets flag within CharacterStateControl
		 * @param	anim
		 * @param	animClass
		 * @param	stateControl
		 */
		private function onEnd( anim:Animation, animClass:Class ):void
		{		
			if ( ClassUtils.getClassByObject( anim ) == animClass )
			{
				node.primary.ended.remove( Command.create( onEnd, animClass ) );
				node.charMotionControl.animEnded = true;
			}
		}

		protected function getCurrentAnim():Class
		{
			return ClassUtils.getClassByObject(node.primary.current);
		}

	}
}