package game.systems.entity.character.clipChar
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import game.components.entity.Children;
	import game.components.entity.character.Talk;
	import game.components.timeline.Timeline;
	import game.nodes.entity.character.clipChar.TalkClipNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
	
	/**
	 * Manages talking for characters not using the standrad rig ( poptropicans, creatures ). 
	 * @author umckiba
	 */
	public class TalkClipSystem extends GameSystem
	{
		private const MOUTH_VALUE:String = "talk";
		//private const EYESTATE_VALUE:String = "casual";
		private const TALK_DELAY:int = 90; 	// delay between word bubble closing and characer resuming default animation sequence
		
		public function TalkClipSystem()
		{
			super(TalkClipNode, updateNode );
			super._defaultPriority = SystemPriorities.update;
		}
		
		private function updateNode( node:TalkClipNode, time : Number ):void
		{
			var talk:Talk = node.talk;
			
			if( talk._active )
			{
				var mouthClip:MovieClip;
				var eyeClip:MovieClip;
				var nodeTimeline:Timeline = node.entity.get(Timeline);
				var children:Children = node.entity.get(Children);
				
				if( talk.isStart )
				{
					talk.isStart = false;
					
					if(nodeTimeline)
						nodeTimeline.gotoAndPlay(talk.talkLabel);
					
					if(children)
					{
						for each(var instance:String in talk.instances)
						{
							var child:Entity = EntityUtils.getChildById(node.entity, instance);
							child.get(Timeline).gotoAndPlay(talk.talkLabel);
						}
					}
					/*if(talk.instanceData)
					{
						mouthClip = MovieClip(talk.instanceData.getInstanceFrom(node.display.displayObject));
						mouthClip.gotoAndPlay(talk.talkLabel);
					}
					else
					{
						MovieClip(node.display.displayObject).gotoAndPlay(talk.talkLabel);
					}*/
					
					// store current values so that they can be returned to when talk completes
	
					// set mouth parts
					/*
					mouth = node.skin.getSkinPart( SkinUtils.MOUTH );
					mouth.setValue(MOUTH_VALUE, false);
					mouth.lock = true;
					*/
					
					// set eyeState
					/*
					if( talk.adjustEyes )
					{
						eyeState = node.skin.getSkinPart( SkinUtils.EYE_STATE );
						eyeState.setValue("casual", false);
						eyeState.lock = true;		// lock assets, unlock once talking is finished, prevents animation from altering them	
					}
					*/
					
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
					
					if(nodeTimeline)
						nodeTimeline.gotoAndPlay(talk.mouthDefaultLabel);
					
					if(children)
					{
						for each(var stopInstance:String in talk.instances)
						{
							var stopChild:Entity = EntityUtils.getChildById(node.entity, stopInstance);
							stopChild.get(Timeline).gotoAndPlay(talk.mouthDefaultLabel);
						}
					}
					
					/*
					// set parts back to previous
					mouth = node.skin.getSkinPart( SkinUtils.MOUTH );
					if( mouth.value == MOUTH_VALUE)
					{
						// revert mouth 
						mouth.lock = false;
						mouth.revertValue();
						
						// revert eyeState
						if( talk.adjustEyes )
						{
							eyeState = node.skin.getSkinPart( SkinUtils.EYE_STATE );
							eyeState.lock = false;
							eyeState.revertValue();
						}
					*/
						
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
						
					}
					*/
				}
				else	// talk is updating
				{
					
				}
				
			}
		}
	}
}

