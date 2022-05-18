package game.scenes.myth.mountOlympus3.bossStates
{	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	import engine.group.Group;
	
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Soar;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TweenUtils;
	
	
	public class ZeusState extends FSMState
	{
		// audio actions
		private static const GLOW:String =		"glow";
		
		// states
		public static const MOVE:String = 		"move";
		public static const GUST:String = 		"gust";
		public static const BOLT:String = 		"bolt";
		public static const ORBS:String = 		"orbs";
		public static const CHARGE:String = 	"charge";
		public static const DEFEAT:String = 	"defeat";
		
		// class variables
		private var _playerNode:CloudCharacterStateNode;

		// labels
		private static const EFFECTS:String = "effects";
		private static const END:String 	= "end";
		private static const SOAR:String 	= "soar";
		private static const STOP:String 	= "stop";
		private static const RAISED:String 	= "raised";
		
		public function ZeusState(){}
		
		/**
		 * Use getter to cast node to CharacterStateNode.
		 */
		public function get node():ZeusStateNode
		{
			return ZeusStateNode(super._node);
		}
		
		// THE DEFAULT START OF EACH STATE
		// SET ANIMATION TO SOAR AND DETERMINE DIRECTION
		override public function start():void
		{
			setSoar();

			// face traget (player)
			var target:Spatial = node.targetSpatial.target;
			if((( target.x > node.spatial.x ) && node.spatial.scaleX > 0 ) || ( target.x < node.spatial.x ) && node.spatial.scaleX < 0 )
			{
				node.spatial.scaleX *= -1;
			}
		}
		
		public function get playerNode():CloudCharacterStateNode
		{
			if( !_playerNode )
			{
				var group:Group = node.owningGroup.group;
				var systemManager:Engine = node.owningGroup.group.shellApi.groupManager.systemManager;
				var cloudPlayerNodeList:NodeList = systemManager.getNodeList( CloudCharacterStateNode );
				_playerNode = cloudPlayerNodeList.head as CloudCharacterStateNode;
			}
			return _playerNode;
		}
		
		public function moveToNext():void
		{
			if( node.fsmControl.state.type != ZeusState.DEFEAT )
			{
				node.fsmControl.setState( ZeusState.MOVE );
			}
		}
		
		// TOGGLE INVINCIBILITY AND ELECTRICITY
		public function setInvincible( active:Boolean = true ):void
		{
			node.boss.invincible = active;
			node.electric.on = active;
			
			if( active )
			{
				node.audio.playCurrentAction( GLOW );
				
				if(!PlatformUtils.isMobileOS)
				{
					node.display.displayObject.filters = new Array( node.boss.colorFill, node.boss.whiteOutline, node.boss.colorGlow );
				}
				TweenUtils.globalTo(node.entity.group, node.display, 0.5, { alpha : 0.9 });
			}
			else
			{
				node.audio.stopAll( EFFECTS );
				
				if(!PlatformUtils.isMobileOS)
				{
					node.display.displayObject.filters = new Array();
				}
				for( var i:int = 0; i < node.electric.sparks.length; i++ )
				{
					node.electric.sparks[i].graphics.clear();
				}
				
				TweenUtils.globalTo(node.entity.group, node.display, 0.4, { alpha : 1 });
			}
		}
		
		/////////////////////////////// HURT ///////////////////////////////
		
		public function hurt( damage:int = 1 ):void
		{	
			// apply damage
			node.boss.health -= damage;
			
			// check defeated
			if( node.boss.health <= 0 )
			{
				node.motion.zeroMotion();
				node.owningGroup.group.shellApi.triggerEvent( "zeus_downed" );
				node.fsmControl.setState( ZeusState.DEFEAT );
			}
			else
			{
				node.boss.showHealthBar();

				// start animation sequence
				if( ClassUtils.getClassByObject(node.primary.current) == Hurt )
				{
					node.timeline.gotoAndPlay(1);
				}
				else
				{
					node.primary.next = Hurt;
					node.timeline.lock = true;
				}
				node.timeline.handleLabel( Animation.LABEL_ENDING, setSoar );
				
				// check advance sequence
				if( node.boss.sequenceLevels.length > 0 )
				{
					checkSequenceAdvance();
				}
			}
		}
		
		private function checkSequenceAdvance():void
		{
			if( node.boss.health < node.boss.sequenceLevels[0] )
			{
				node.boss.sequenceLevels.shift();	// remove first sequence value
				node.boss.currentAttackSequence = node.boss.attackSequences.shift();
				node.boss.currentAttackIndex = 0;
			}
		}

		private function setSoar( ...args ):void
		{
			if( ClassUtils.getClassByObject( node.primary.current ) != Soar )
			{
				node.primary.next = Soar;
				node.timeline.lock = true;
				node.timeline.handleLabel( Animation.LABEL_BEGINNING, setFace );
			}
			else
			{
				setFace();
			}
		}
		
		private function setFace():void
		{
			node.timeline.gotoAndPlay( 3 );
			SkinUtils.setEyeStates( node.entity, "mean" );
			SkinUtils.setSkinPart( node.entity, SkinUtils.MOUTH, "shadyCop" );
		}
	}
}