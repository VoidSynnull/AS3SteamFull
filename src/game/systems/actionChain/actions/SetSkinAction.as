package game.systems.actionChain.actions
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.util.Command;
	
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.data.animation.Animation;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.ui.elements.ConfirmationDialogBox;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.SkinUtils;

	// Set skin part of entity or entities 
	// Can be used for any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") or facing ("FACING") or nearest ("NEAREST") characters
	public class SetSkinAction extends ActionCommand 
	{
		private var partType:String;
		private var partId:*;
		private var permanent:Boolean;
		private var waitForLoad:Boolean;
		private var revert:Boolean = false;
		private var color:uint = 1;
		private var suffix:Number = 0;
		private var colorize:Boolean = true;
		
		private var _charType:String;
		private var _oldParts:Dictionary = new Dictionary();
		private var _callback:Function;
		private var _counter:int = 0;
		private var randomize:Boolean = false;
		/**
		 * Set skin part of entity or entities 
         * @param char			Entity whose skin to update (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param partType		Name of part type
         * @param partId		Name of part - can be comma delimited list (for random use) or in form: "M:part1,part2,part3|F:part1,part2,part3" (for random looks by gender)
		 * @param permanent		Make part permanent
		 * @param waitForLoad	Wait for part to load - if true, the action will not complete until the part is fully loaded and will check if there is a timeline to play
         * @param revert		Revert to permanent if the part has already been applied (only works if the previous update was not permanent)
         * @param color			Color value for part
		 */
		public function SetSkinAction( char:*, partType:String, partId:*, permanent:Boolean=false, waitForLoad:Boolean=false, revert:Boolean = false, color:uint = 1, suffix:Number=0, colorize:Boolean=false, randomize:Boolean=false ) 
		{
			// if single entity, then store
			if (char is Entity)
			{
				this.entity = char;
			}
			else if (char is String)
			{
				// else remember character type string
				_charType = char;
			}

			this.partType = partType;
			this.partId = partId;
			this.permanent = permanent;
			this.waitForLoad = waitForLoad;
			this.revert = revert;
			this.color = color;
			this.suffix = suffix;
			this.colorize = colorize;
			this.randomize = randomize;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			_callback = callback;
			_counter = 0;
			
			var entityArray:Vector.<Entity>;
			
			// if NPCs or ALL or FACING or NEAREST
			if (_charType)
			{
				// don't allow on Poptropicon islands
				var currentIsland:String = group.shellApi.island;
				if ( (currentIsland == "con1") || (currentIsland == "con2") || (currentIsland == "con3") )
				{
					// show block dialog
					showBlockDialog(group);
					callback();
					return;
				}
				entityArray = CharacterGroup(group.getGroupById("characterGroup")).getNPCs(_charType);
				
				// if no entities then end action
				if (entityArray.length == 0)
				{
					callback();
					return;
				}
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
			
			// determine new part (can be string or color value)
			var part:*;
			if (partId is String)
			{
				// if gender split for looks
				var split:int = partId.indexOf("|");
				if (split != -1)
				{
					var male:Array = [];
					var female:Array = [];
					var chunk:String = partId.substr(2,split-2);
					if (chunk != "")
						male = chunk.split(",");
					chunk = partId.substr(split+3);
					female = chunk.split(",");
				}
				else if (partId.indexOf(",") != -1)
				{
					// if comma delimited list
					var partArray:Array = partId.split(",");
					var pos:int = Math.floor(partArray.length * Math.random());
					part = partArray[pos];
				}
				else
				{
					// if single part
					if(suffix != 0)
						part = partId + suffix;
					else
						part = partId;
					
					//trace(part);
				}
			}
			else
			{
				part = partId;
			}
			
			// for each char
			for each(var char:Entity in entityArray)
			{
				// don't update blimp NPC
				if (char.get(Id).id == "custom_blimp_npc")
					continue;
				if(char.get(BitmapCharacter) != null)
					continue;
				
				// increment entity counter
				_counter++;
				if(randomize)
				{
					var pArray:Array = partId.split(",");
					var position:int = Math.floor(partArray.length * Math.random());
					part = partArray[position];
				}
				// set final part to part
				var finalPart:* = part;
				// if part is null, then assume gender specific parts
				if (part == null)
				{
					// if male
					if( SkinUtils.getLook(char).getValue(SkinUtils.GENDER) == SkinUtils.GENDER_MALE)
					{
						// if no male parts then skip out
						if (male.length == 0)
						{
							completeAction();
							continue;
						}
						else
						{
							// if parts
							finalPart = getRandomGenderPart(char, male);
						}
					}
					else
					{
						// if no female parts then skip out
						if (female.length == 0)
						{
							completeAction();
							continue;
						}
						else
						{
							// if parts
							finalPart = getRandomGenderPart(char, female);
						}
					}
				}
				if(SkinUtils.getLook(char, false) != null)
					_oldParts[char] = SkinUtils.getLook(char, false).getValue(partType);
				if ( waitForLoad ) 
				{
					// if not reverting then apply skin part
					if (!checkRevert(char))
						SkinUtils.setSkinPart( char, partType, finalPart, permanent, Command.create(loadedSkinPart, char) );
				} 
				else 
				{
					// if not reverting then apply skin part
					if (!checkRevert(char))
						SkinUtils.setSkinPart( char, partType, finalPart, permanent );
					completeAction();
				}
			}
		}
		
		/**
		 * get random gender part from gender array and set array index for all future parts 
		 * @param char
		 * @param index
		 * @param arr
		 * @return String
		 */
		private function getRandomGenderPart(char:Entity, arr:Array):String
		{
			var index:int = -1;
			
			// get index if already applied, then get it
			if (char.get(Display).displayObject.arrayIndex != null)
				index = char.get(Display).displayObject.arrayIndex;
			
			// if no index yet, then create random one and apply to char
			if (index == -1)
			{
				index = Math.floor(arr.length * Math.random());
				char.get(Display).displayObject.arrayIndex = index;
			}
			// keep index within range
			if (index > arr.length - 1)
				index = arr.length - 1;
			return arr[index];
		}
		
		/**
		 * Check if need to revert 
		 * @param char
		 * @return boolean - true if reverting
		 */
		private function checkRevert(char:Entity):Boolean
		{
			// if reverting and parts match, then revert
			if ((revert) && (_oldParts[char] == partId))
			{
				var skinPartEntity:Entity = SkinUtils.getSkinPartEntity( char, partType);
				if (skinPartEntity)
					SkinPart(skinPartEntity.get( SkinPart )).revertValue();
				return true;
			}
			return false;
		}
		
		/**
		 * Show dialog saying that the action is blocked
		 * @param group
		 */
		private function showBlockDialog( group:Group ):void
		{
			var ID:String = "BlockAbility";
			if (group.getGroupById(ID) == null)
			{
				var dialogBox:ConfirmationDialogBox = new ConfirmationDialogBox(1, "This feature cannot be used on this island.");
				dialogBox.id = ID;
				dialogBox = ConfirmationDialogBox(group.addChildGroup(dialogBox));
				dialogBox.darkenBackground     = true;
				dialogBox.pauseParent         = false;
				dialogBox.init(Scene(group).overlayContainer);
			}
		}
		
		/**
		 * When skin part loaded 
		 * @param skinPart
		 * @param char
		 */
		private function loadedSkinPart(skinPart:SkinPart, char:Entity):void
		{
			completeAction();
			
			var timeline:Timeline = CharUtils.getPart(char, partType).get(Timeline);	
			if(timeline)
				timeline.handleLabel(Animation.LABEL_ENDING, Command.create(doneAnim, char));
			
			// if color passed, then colorize part
			if (color != 1 && colorize == true)
			{
				var partEntity:Entity = CharUtils.getPart(this.entity, partType);
				if (partEntity)
				{
					var clip:DisplayObject = partEntity.get(Display).displayObject;
					ColorUtil.colorize(clip, color);
				}
			}
		}
		
		/**
		 * When part timeline done 
		 * @param char
		 */
		private function doneAnim(char:Entity):void
		{
			if(!_oldParts[char])
				SkinUtils.emptySkinPart(char, partType);
			else
				SkinUtils.setSkinPart(char, partType, _oldParts[char]);
		}
		
		/**
		 * When action completed for entity 
		 */
		private function completeAction():void
		{
			// decrement for each entity
			_counter--;
			// only execute callback once (since there may be many completions at the same time)
			if (_counter == 0)
				_callback();
		}
	}
}