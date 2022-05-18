package game.systems.entity.character
{
	import ash.core.Entity;
	
	import game.components.entity.character.Talk;
	import game.components.entity.character.part.SkinPart;
	import game.components.entity.character.part.eye.Eyes;
	import game.nodes.entity.character.TalkRigNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.util.CharUtils;
	import game.util.SkinUtils;
	
	/**
	 * Manages talking for characters using the standrad rig ( poptropicans, creatures ). 
	 * @author umckiba
	 * 
	 */
	public class TalkRigSystem extends GameSystem
	{
		private const TALK_DELAY:int = 90; 	// delay between word bubble closing and characer resuming default animation sequence
		
		public function TalkRigSystem()
		{
			super(TalkRigNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode( node:TalkRigNode, time : Number ):void
		{
			var talk:Talk = node.talk;
			
			if( talk._active )
			{
				var mouth:SkinPart;
				var eyeStateSkinPart:SkinPart;
				var eyes:Eyes;
				
				if( talk.isStart )
				{
					talk.isStart = false;
						
					// TODO :: store current values so that they can be returned to when talk completes?

					// set mouth parts
					mouth = node.skin.getSkinPart( SkinUtils.MOUTH );
					mouth.setValue(talk.talkPart, false);
					mouth.lock = true;
					
					// set eyeState
					if( talk.adjustEyes )
					{
						var eyeEntity:Entity = CharUtils.getPart( node.entity, SkinUtils.EYES );
						if( eyeEntity )
						{
							eyes = eyeEntity.get(Eyes);
							if( eyes )
							{
								eyes.permanentState = SkinUtils.getSkinPart( node.entity, SkinUtils.EYE_STATE ).permanent;
								eyes.previousStore();
								eyes.state = EyeSystem.TALK;
								eyes.pupilState	= EyeSystem.FRONT;
								eyes.locked = true;
							}
						}
					}

					// determine animation 
					// NOTE :: if waitForEnd is true, current animation must end for auto to turn on
					/*
					if( node.fsmControl )
					{
						CharUtils.stateDrivenOn( char, true );
					}
					else
					{
						CharUtils.setAnim( char, Stand, true );
					}
					*/
				}
				else if ( talk.isEnd )
				{
					talk._active = false;
					talk.isEnd = false;
					
					// set parts back to previous
					mouth = node.skin.getSkinPart( SkinUtils.MOUTH );
					if( mouth.value == talk.talkPart)
					{
						// revert mouth 
						mouth.lock = false;
						mouth.revertValue();
						
						// revert eyeState
						if( talk.adjustEyes )
						{
						 	eyeEntity = CharUtils.getPart( node.entity, SkinUtils.EYES );
							if( eyeEntity )
							{
								eyes = eyeEntity.get(Eyes);
								if( eyes )
								{
									eyes.locked = false;
									eyes.previousApply();
								}
							}
						}
						
						// set animation to previosu animation
						/*
						if( node.fsmControl )
						{
							// TODO :: should really only turn off if it was not on in the first place
							CharUtils.stateDrivenOff( char, TALK_DELAY );
						}
						else
						{
							// if was set to Stand, set a duration to end Stand
							var rigAnim:RigAnimation = CharUtils.getRigAnim( char );
							
							if( rigAnim.previous )	// revert to previous
							{
								if( Utils.getClass(rigAnim.current) == Stand )
								{
									rigAnim.duration = TALK_DELAY;	// once duration ios up should return to previous animation
								}
							}
							// else let end naturally
							
							// reset anim sequence
							var animSequencer:AnimationSequencer = AnimationControl(char.get(AnimationControl)).getEntityAt(0).get( AnimationSequencer );
							if ( animSequencer )
							{
								if( animSequencer.active )
								{
									animSequencer.reset();
								}
							}
						}
						*/
					}
				}
			}
		}
	}
}