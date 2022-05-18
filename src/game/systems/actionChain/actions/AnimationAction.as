package game.systems.actionChain.actions
{
	import flash.utils.getTimer;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.RigAnimation;
	import game.data.animation.Animation;
	import game.data.animation.entity.character.Disco;
	import game.data.animation.entity.character.Stand;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	// Play a Poptropican character animation
	// Can be used to animate any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") characters or follower ("FOLLOWER")
	// Note: if playing the SAME animation action in a row, add a slight delay (0.01 sec) between them or else the second one won't play
	public class AnimationAction extends ActionCommand 
	{
		private var animationClass:Class;
		private var waitLabel:String;
		private var maxFrames:int; // Maximum time to run an animation.
		private var stopOnLabel:Boolean;
		private var fsmActive:Boolean;
		private var repeat:int = 0;
		
		private var _charType:String;
		private var _callback:Function;
		private var _counter:int = 0;
		
		private var entityArray:Vector.<Entity>;
		
		private var partType:String;
		private var partValue:String;
		private var _origValue:String;
		private var _hasRepeat:Boolean = false;
		private var labelReached:Function;
		
		/**
		 * Play a Poptropican character animation
		 * @param char				Entity to assign animation to (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param animationClass	Animation Class to be assigned to character.
		 * @param waitLabel			Label to end animation at, a value of "" will play naturally. Use "none" in xml.
		 * @param max_frames		Maximum frames animation will play, a value of zero will play naturally.
		 * @param stopOnLabel		Stop on label frame - when set to false, the animation will continue but the next action will trigger (useful when you want the next action to execute on the trigger label)
		 * @param fsmActive			fsmActive state (set to true if you want to be able to click out of an animation, such as Disco loop)
		 * @param repeat			number of repeats (default is 1) expects looping animation only
		 * @param partType			part type to swap before animation
		 * @param partValue			part value to swap before animation (will revert after animation)
		 */
		
		public function AnimationAction( char:*, animationClass:Class, waitLabel:String="", maxFrames:int=0, stopOnLabel:Boolean = true, fsmActive:Boolean = false, repeat:int = 1, partType:String = null, partValue:String = null) 
		{
			// if single entity, then add to array
			if (char is Entity)
			{
				this.entity = char;
			}
			else if (char is String)
			{
				// else remember character type string
				_charType = char;
			}
			
			if (waitLabel == "none")
				waitLabel = "";
			
			this.animationClass = animationClass;
			this.waitLabel = waitLabel;
			this.maxFrames = maxFrames;
			this.stopOnLabel = stopOnLabel;
			this.fsmActive = fsmActive;
			this.repeat = repeat;
			this.partType = partType;
			this.partValue = partValue;
			
			if (this.repeat != 1)
			{
				_hasRepeat = true;
			}
		}
		
		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			_callback = callback;
			_counter = 0;
			
			// if NPCs or ALL or FOLLOWER
			if (_charType)
			{
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(_charType);
			}
			else if (entity)
			{
				// if entity then create vector with single entity
				entityArray = new <Entity>[entity];
			}
			else
			{
				// else fail gracefully
				callback();
				return;
			}
			
			// swap part if given and only one entity
			if ((entityArray.length == 1) && (partType != null) && (partValue != null))
			{
				_origValue = SkinUtils.getSkinPart( entityArray[0], partType).value;
				SkinUtils.setSkinPart( entityArray[0], partType, partValue, false);
			}

			// for each char
			for each (var char:Entity in entityArray)
			{
				_counter++;
				
				CharUtils.getRigAnim( char ).ended.add( Command.create(_animationEnded, char) );
				// RLH: made fsmActive a param that is passed to action (defaults to false)
				CharUtils.setAnim( char, animationClass, false, maxFrames, 0, false, fsmActive );
				
				if( DataUtils.validString(waitLabel) )
				{
					labelReached = Command.create(_labelReached, char);
					CharUtils.getTimeline( char ).labelReached.add(labelReached);
				}
			}
		}
		
		/**
		 * When animation label reached 
		 * @param label
		 * @param char
		 */
		private function _labelReached( label:String, char:Entity ):void
		{
			if ( label == waitLabel ) 
			{
				if (repeat == 1)
				{
					if( stopOnLabel )
						( char.get( RigAnimation ) as RigAnimation ).manualEnd = true;
					else
						_animationEnded(null, char);
				}
				else
				{
					repeat--;
				}
			}
		}
		
		/**
		 * When animation has ended (note: this can be called twice if waitLabel is valid)
		 * @param endingAnim
		 * @param char
		 */
		private function _animationEnded( endingAnim:Animation = null, char:Entity = null ):void 
		{
			// decrement for each entity
			_counter--;
			
			if (_origValue != null)
			{
				SkinUtils.setSkinPart( entityArray[0], partType, _origValue, false);
			}

			var rigAnim:RigAnimation = CharUtils.getRigAnim( char );
			rigAnim.ended.remove( _animationEnded );			
			CharUtils.getTimeline( char ).labelReached.remove(labelReached);
			
			// if repeating, then need to set manual end because animation is looping
			if (_hasRepeat)
			{
				rigAnim.manualEnd = true;
			}
				
			// only execute callback once (since there may be many completions at the same time)
			if (_counter == 0)
			{
				_callback();
			}
		}
	}
}
