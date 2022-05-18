package game.systems.entity.character.states
{
	import engine.util.Command;
	
	import game.data.animation.Animation;
	import game.nodes.entity.character.FlyingPlatformStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	
	public class FlyingPlatformState extends FSMState
	{
		public static const HURT:String				= 	"hurt";
		public static const RIDE:String				= 	"ride";
		
		public static const STATES:Vector.<String> 	= new <String>[ HURT, RIDE ];
		
		public function FlyingPlatformState()
		{
			super();
		}
		
		public function get node():FlyingPlatformStateNode
		{
			return FlyingPlatformStateNode( super._node );
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
	}
}