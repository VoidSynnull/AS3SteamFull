package game.scenes.ghd.lostTriangle.states
{
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.input.Input;
	import game.data.animation.Animation;
	import game.scenes.ghd.lostTriangle.nodes.JetPackStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	
	
	public class JetPackState extends FSMState
	{
		protected var _input:Input;
		protected var _emitter:Emitter;
		
		private const X:String							=	"X";
		public static const HOVER:String				= 	"hover";
		public static const TRIGGER:String				= 	"trigger";
		public static const HURT:String					=	"hurt";
		public static const PROPEL:String				=	"propel";
		public static const STATES:Vector.<String> 	= new <String>[ HOVER, HURT, PROPEL ];
		
		public function JetPackState()
		{
			super();
		}
		
		public function init( input:Input = null, emitter:Emitter = null ):void
		{			
			_input = input;
			_emitter = emitter;
		}
		
		public function get node():JetPackStateNode
		{
			return JetPackStateNode( super._node );
		}
		
		override public function update( time:Number ):void
		{
			
		}
		
		override public function check():Boolean
		{
			if( !node.jetpackHealth.hurting && !node.jetpackHealth.complete )
			{
				if( node.looperCollider.collisionType == "miasmaBottom" )
				{
					node.motion.acceleration.y = 0;
					node.motion.previousAcceleration.y = 0;
					node.motion.lastVelocity.y = 0;
					node.motion.velocity.y = -200;	
				}
				
				else if( node.looperCollider.collisionType == "miasmaTop" )
				{
					node.motion.acceleration.y = 0;
					node.motion.previousAcceleration.y = 0;
					node.motion.lastVelocity.y = 0;
					node.motion.velocity.y = 200;
				}
				
				node.jetpackHealth.hurting = true;
				node.fsmControl.setState( JetPackState.HURT );
				return true;
			}
			else
			{
				return false;
			}
		}
		
		/**
		 * Set the animation
		 * @param	node
		 * @param	animClass
		 */
		protected function setAnim( animClass:Class, listendForEnd:Boolean = true ):void
		{	
			node.primary.next = animClass;
			
			if ( listendForEnd )
			{
				node.primary.ended.add( Command.create( onEnd, animClass ));
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
			return ClassUtils.getClassByObject( node.primary.current );
		}
		
		public function onActiveInput( input:Input ):void
		{
			if( !node.jetpackHealth.hurting && node.fsmControl.state.type != JetPackState.HURT && node.fsmControl.state.type != JetPackState.PROPEL )
			{
				node.fsmControl.setState( JetPackState.PROPEL );
			}
		}
		
		public function onInactiveInput( input:Input ):void
		{
			if( !node.jetpackHealth.hurting && node.fsmControl.state.type == JetPackState.PROPEL )
			{
				node.fsmControl.setState( JetPackState.HOVER );
			}
		}
	}
}