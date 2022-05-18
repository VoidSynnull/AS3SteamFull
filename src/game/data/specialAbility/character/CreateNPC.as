// Used by:
// Card 2878 using item ???

package game.data.specialAbility.character
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.scene.characterDialog.DialogData;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.SkinUtils;
	
	/**
	 * random Poptropican NPC in front of avatar
	 * 
	 * Optional params: (use comma-delimited string if more than one random NPC)
	 * numNPCs				Uint		Number of NPCs
	 * gender				String		Gender (male or female)
	 * skinColor			String		Skin color (default is black)
	 * hairColor			String		Hair color (default is pink flesh)
	 * eyesFrame			String		Eye frame ID (default is squint)
	 * mouthFrame			String		Mouth frame ID (default is 1)
	 * marksFrame			String		Marks frame ID
	 * facialFrame			String		Facial frame ID
	 * hairFrame			String		Hair frame ID (default is bald)
	 * shirtFrame			String		Shirt frame ID (bug - doesn't seem to carry over to follower) 
	 * pantsFrame			String		Pants frame ID
	 * packFrame			String		Pack frame ID
	 * itemFrame			String		Item frame ID
	 * overshirtFram		String		Overshirt frame ID
	 * overpantsFrame		String		Overpants frame ID
	 * scaleSize			String		Scaling factor for follower (default is 0, which results in 1.0 for normal size)
	 * randomDialog			Array		Array of random dialog strings (grouped by npc)
	 */
	public dynamic class CreateNPC extends SpecialAbility
	{
		override public function init(node:SpecialAbilityNode):void
		{
			super.init( node );
			_node = node;		
		}
		
		override public function activate( node:SpecialAbilityNode ):void
		{
			// if not suppressed and not active
			if (!super.data.isActive)
			{
				if (_numNPCs != 1)
				{
					while (true)
					{
						var index:int = Math.floor(Math.random() * _numNPCs);
						if (index != _index)
						{
							_index = index;
							break;
						}
					}
				}

					// setup look for npc
				var _look:LookData = new LookData();
				_look.applyAspect( new LookAspectData( SkinUtils.GENDER, getRandomAppearance(_gender) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.HAIR_COLOR, uint(getRandomAppearance(_hairColor)) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.SKIN_COLOR, uint(getRandomAppearance(_skinColor)) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.FACIAL, getRandomAppearance(_facialFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.EYE_STATE, getRandomAppearance(_eyesFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.MOUTH, getRandomAppearance(_mouthFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.MARKS, getRandomAppearance(_marksFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.HAIR, getRandomAppearance(_hairFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.PANTS, getRandomAppearance(_pantsFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.SHIRT, getRandomAppearance(_shirtFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.PACK, getRandomAppearance(_packFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.ITEM, getRandomAppearance(_itemFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, getRandomAppearance(_overshirtFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.OVERPANTS, getRandomAppearance(_overpantsFrame) ) );
				_look.applyAspect( new LookAspectData( SkinUtils.EYES, getRandomAppearance(_eyeType) ) );
				_look.applyAspect(new LookAspectData("variant"));
				if (_scaleSize != null)
					_scale = Number(getRandomAppearance(_scaleSize));

				
				trace("CreateNPC: create NPC with look: " + _look);
				// NOTE: if you are not seeing changes to the special ability, you will need to push the xml file live

				// get scale and direction and position
				var charSpatial:Spatial = super.entity.get(Spatial);
				var xPos:Number = charSpatial.x;
				var yPos:Number = charSpatial.y;			
				var scaleX:Number = charSpatial.scaleX;
				var dir:int = 1;
				if (scaleX < 0)
					dir = -1;
				
				// create NPC in front of player
				var charGroup:CharacterGroup = super.group.getGroupById("characterGroup") as CharacterGroup;
				_npc = charGroup.createNpc("popNPC", _look, xPos - dir * 85, yPos + 40, "left", "", null, onNPCLoaded);
				
				_npc.get(Display).visible = false;
			}
		}
		
		private function getRandomAppearance(value:*):*
		{
			if (_numNPCs == 1)
				return value;
			else
			{
				var arr:Array = String(value).split(",");
				if (_index > arr.length - 1)
					return arr[0];
				else
					return arr[_index];
			}
		}
		
		/**
		 * When NPC loaded 
		 * @param charEntity
		 */
		private function onNPCLoaded( charEntity:Entity = null):void
		{
			trace("CreateNPC: NPC loaded");
			super.setActive( true );
			
			// set behind player
			DisplayUtils.moveToOverUnder(charEntity.get(Display).displayObject, shellApi.player.get(Display).displayObject, false);
			
			// make NPC face player
			_npc.get(Spatial).scaleX = -super.entity.get(Spatial).scaleX;

			// scale avatar if scale
			if (_scale != 0)
				CharUtils.setScale(_npc, _scale * 0.36);
			
			_npc.get(Display).visible = true;
			
			if (_randomDialog != null)
				doDialog();
		}
		
		/**
		 * Trigger dialog
		 */
		private function doDialog():void
		{
			var dialog:Dialog = _npc.get( Dialog );
			if (dialog)
			{
				// play random dialog based on NPC
				var numDialogs:int = Math.floor(_randomDialog.length/_numNPCs);
				var num:int = Math.floor(numDialogs * Math.random());
				var message:String = _randomDialog[_index * numDialogs + num];
				message = message.replace("|",",");
				dialog.say(message);
				dialog.complete.add( dialogCompleted );
			}
		}
		
		private function dialogCompleted(data:DialogData):void
		{
			super.group.removeEntity(_npc);
			super.setActive( false );
		}
		
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			// remove follower
			if( _npc )
				super.group.removeEntity(_npc);		
		}
		
		public var _numNPCs:uint = 1;
		public var _gender:String = SkinUtils.GENDER_MALE;
		public var _skinColor:String = "0xFFCC66";
		public var _hairColor:String = "0x0";
		public var _eyesFrame:String = "squint";
		public var _mouthFrame:String = "1";
		public var _marksFrame:String = "";
		public var _facialFrame:String = "";
		public var _hairFrame:String = "empty";
		public var _shirtFrame:String = "";
		public var _pantsFrame:String = "";
		public var _packFrame:String = "";
		public var _itemFrame:String = "";
		public var _overshirtFrame:String = "";
		public var _overpantsFrame:String = "";
		public var _eyeType:String = "eyes";
		public var _scaleSize:String;
		
		
		public var _randomDialog:Array;
		
		private var _index:uint = 0;
		private var _npc:Entity;
		private var _node:SpecialAbilityNode;
		private var _scale:Number = 0;
	}
}
