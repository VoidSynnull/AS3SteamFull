// Used by:
// Card 3070 using ability shrink

package game.systems.actionChain.actions
{
	import ash.core.Entity;
	
	import engine.group.Group;
	
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.CharacterGroup;
	import game.systems.actionChain.ActionCommand;
	import game.util.CharUtils;
	import engine.components.Spatial;

	// Set scale of entity or entities 
	// Can be used for any NPC, the player's avatar, all NPCs ("NPCS") or all ("ALL") or facing ("FACING") characters
	public class SetScaleAction extends ActionCommand 
	{
		private var scale:Number = 0.18; // half size is default
		private var toggle:Boolean = false; // toggle size
		
		private var _charType:String;

		/**
		 * Set scale of entity or entities  
         * @param char		Entity whose scale to update (can be a string constant "ALL" or "NPCS" or "FACING" to indicate an array of entities) 
		 * @param scale		Scale factor (default is half size)
		 * @param toggle	Toggle between sizes (default is false)
		 */
		public function SetScaleAction( char:*, scale:Number = 0.18, toggle:Boolean = false) 
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

			this.scale = scale;
			this.toggle = toggle;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void 
		{
			var entityArray:Vector.<Entity>;
			
			// if NPCs or ALL
			if (_charType)
			{
				if(_charType == "[entity]")
				{
					entityArray = new <Entity>[node.entity];
				}
				else
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
			
			// for each char, scale
			for each(var char:Entity in entityArray)
			{
				var curScale:Number = char.get(Spatial).scale;
				if ((curScale != 0.36) && (toggle))
					CharUtils.setScale(char, 0.36);
				else
				 CharUtils.setScale(char, scale);
			}
			callback();
		}
		
		override public function revert( group:Group ):void
		{
			// set single entity scale to standard size
			if (entity)
				CharUtils.setScale(entity, 0.36);
		}
	}
}