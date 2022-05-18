package game.scenes.survival5.chase.states
{	
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.input.Input;
	import game.data.animation.Animation;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.entity.character.Stand;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.managers.ScreenManager;
	import game.scenes.survival5.chase.nodes.RunningCharacterStateNode;
	import game.systems.animation.FSMState;
	import game.util.ClassUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;

	public class RunningCharacterState extends FSMState
	{		
		private var originalMouth:SkinPart;
		private var originalEyeState:SkinPart;
		
		protected var _eyeState:LookAspectData;
		protected var _eyes:Eyes
		protected var _uiHead:Entity;
		private var _uiHeadSpatial:Spatial;
		private var _animationLibrary:AnimationLibrary;
		private var CONSTANT:Number;
		protected var _viewportRatioY:Number;
		private var _offsetX:Number = 0;
		protected var _isReality:Boolean = false;
		protected var _winFunction:Function;
		private var _won:Boolean = false;
		
		protected static const LOST_VAN_BUREN:String 			= 	"lost_van_buren";
		protected static const FELL_IN_PIT:String 				=	"fell_in_pit";
		protected static const REPOSITION_PIT_COVER:String 		=	"reposition_pit_cover";
		public static const HURT:String 				=	"hurt";
		public static const JUMP:String 				=	"jump";
		public static const ROLL:String 				=	"roll";
		public static const RUN:String 					=	"run";
		public static const STUMBLE:String 				=	"stumble";
		public static const STATES:Vector.<String> 	= new <String>[ HURT, JUMP, ROLL, RUN, STUMBLE ];
		
		
		private var _scaleClip:MovieClip;
		
		public function RunningCharacterState()
		{
		}
		
		/**
		 * Use getter to _uiHead.
		 */
		public function addUIHead( entity:Entity, viewportRatio:Number, offset:Number=0 ):void
		{
			_uiHead = entity;
			_uiHeadSpatial = entity.get( Spatial );
			
			_offsetX = offset;
			
			var rig:Rig = _uiHead.get( Rig );
			var eyeEntity:Entity = rig.parts[ SkinUtils.EYES ];
			_eyes = eyeEntity.get( Eyes );
			
			var lookData:LookData = SkinUtils.getLook( _uiHead );
			_eyeState = lookData.getAspect( "eyeState" );
		
			CONSTANT = 940 * viewportRatio;
		}
		public function setClip(clip:MovieClip):void{_scaleClip = clip};
		public function setWinFunction(inFunction:Function):void{_winFunction = inFunction};

		/**
		 * Use getter to cast node to CharacterStateNode.
		 */
		public function get node():RunningCharacterStateNode
		{
			return RunningCharacterStateNode( super._node );
		}
		
		override public function update( time:Number ):void
		{
			if( _uiHeadSpatial && node.motionMaster.active )
			{
				if(!_isReality)
				{
					if( - node.motionMaster._distanceX / node.motionMaster.goalDistance >= .85 )
					{
						node.owningGroup.group.shellApi.triggerEvent( REPOSITION_PIT_COVER );
					}
					
					if( - node.motionMaster._distanceX / node.motionMaster.goalDistance >= .925 )
					{
						node.owningGroup.group.shellApi.triggerEvent( LOST_VAN_BUREN, true );
					}
					else
					{
						_uiHeadSpatial.x = 30 - ( node.motionMaster._distanceX / node.motionMaster.goalDistance * CONSTANT );
					}
				}
				_eyes.canBlink = false;
			}
			else if(_isReality && node.motionMaster.active)
			{
				
				if( - node.motionMaster._distanceX / node.motionMaster.goalDistance >= .925 )
				{
					if(!_won)
					{
						_winFunction();
						_won = true;
					}
					//node.owningGroup.group.shellApi.currentScene.addChildGroup(new RankingsPopup(node.owningGroup.group.shellApi.currentScene.overlayContainer));
				}
				else
				{
					_scaleClip.scaleX = ( node.motionMaster._distanceX / node.motionMaster.goalDistance ) *-1;
					//_scaleClip.scaleY = ( node.motionMaster._distanceX / node.motionMaster.goalDistance )*-1;

				}
				
			}
		}

		/**
		 * Resets max velocity and sets friction to 0.
		 * @param	node
		 * @param	animClass
		 */
		protected function resetMotion():void
		{		
			node.motion.maxVelocity.x = node.charMotionControl.maxVelocityX;
			node.motion.maxVelocity.y = node.charMotionControl.maxVelocityY;
			node.motion.friction.x = 0;
		}
		
		public function stopMotion():void
		{
			setAnim( Stand );
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
			var state:String = node.fsmControl.state.type;
			if( !_viewportRatioY ) 
			{
				_viewportRatioY = node.owningGroup.group.shellApi.viewportHeight / ScreenManager.GAME_HEIGHT;
			}
			
			if(!_isReality)
			{
				if( state != RunningCharacterState.JUMP && state != RunningCharacterState.HURT && state != RunningCharacterState.STUMBLE && state != RunningCharacterState.ROLL )
				{                                     
					if( input.target.y < node.spatial.y * _viewportRatioY )
					{
						node.fsmControl.setState( RunningCharacterState.JUMP );
					}
					else
					{
						node.fsmControl.setState( RunningCharacterState.ROLL );
					}
				}
			}
			else
			{
				if( state != RunningCharacterState.JUMP && state != RunningCharacterState.HURT && state != RunningCharacterState.STUMBLE && state != RunningCharacterState.ROLL )
				{  
					if( PlatformUtils.isDesktop )
					{
						node.fsmControl.setState( RunningCharacterState.JUMP );
					}
					else
					{
						if(!input.inputStateDown)                                    
							node.fsmControl.setState( RunningCharacterState.JUMP );
					}
				}
			}
		}
		public function setReality(isReality:Boolean):void { _isReality = isReality; }
	}
}