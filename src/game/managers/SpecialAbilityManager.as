package game.managers
{
	import flash.net.SharedObject;
	
	import ash.core.Entity;
	
	import engine.Manager;
	import engine.util.Command;
	
	import game.components.entity.character.Player;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.specialAbility.SpecialAbilityData;
	import game.proxy.DataStoreRequest;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.PlatformUtils;
	import game.util.ProxyUtils;
	
	public class SpecialAbilityManager extends Manager
	{
		public var doNotBroadcastAbilities:Array = new Array("FreezeGame",
							"GlitchPower");
		public function SpecialAbilityManager()
		{
		}
		
		public function addSpecialAbilityById(character:Entity, id:String, activate:Boolean = false):SpecialAbilityData
		{
			var data:SpecialAbilityData = new SpecialAbilityData();
			shellApi.loadFileWithServerFallback(shellApi.dataPrefix + "entity/character/abilities/" + id + ".xml", Command.create(abilityDataLoaded, data, character, activate));
			return data;
		}
		
		private function abilityDataLoaded(xml:XML, data:SpecialAbilityData, character:Entity, activate:Boolean):void
		{
			if(xml)
			{
				data.parse(xml);
				
				// if the special ability is not triggerable, then it should be applied right away
				// if it is triggerable, then go by what is passed.
				if(!data.triggerable)
					activate = true;
				
				if( data.isValidIsland(shellApi.island ) )
				{
					var removeData:SpecialAbilityData = CharUtils.addSpecialAbility(character, data, activate);
					
					if(character.has(Player) && data.saveToProfile)
					{		
						//if(removeData)removeSpecialAbility(character, removeData.id);
						
						if(shellApi.profileManager.active.specialAbilities.indexOf(data.id) == -1)
						{
							shellApi.profileManager.active.specialAbilities.push(data.id);
							shellApi.profileManager.save();
							syncAbilities();
						}
					}
				}
			}
			else
			{
				trace("SpecialAbilityManager :: XML was null :: the id passed to be added does not have a corresponding xml file.");
			}
		}
		
		/**
		 * Remove all special abilities from player and save
		 */
		public function removeAllSpecialAbilities():void
		{
			// remove from player
			for each (var id:String in shellApi.profileManager.active.specialAbilities)
			{
				CharUtils.removeSpecialAbilityById(shellApi.player, id);
			}
			// clear by setting empty array
			shellApi.profileManager.active.specialAbilities = new Array();
			// save
			shellApi.profileManager.save();
			syncAbilities();
		}
		
		/**
		 * Remove special ability from player and save profile
		 * @param id ability id
		 */
		public function removeSpecialAbilityFromPlayer(id:String, save:Boolean = true, checkControl:Boolean=false):void
		{
			trace("Remove special ability: " + id);
			var abilities:Array = shellApi.profileManager.active.specialAbilities;
			for(var i:Number = 0 ; i < abilities.length; i++)
			{				
				if(DataUtils.getString(abilities[i]) == id)
				{
					if(checkControl)
					{
						var control:SpecialAbilityControl = shellApi.player.get(SpecialAbilityControl);
						for(var j:Number = 0; j<control.specials.length;j++)
						{
							var special:String = control.specials[j].id;
							if(special == id)
							{
								control.specials.removeAt(i);
							}
						}
					}
					trace("Remove special ability: found: " + id);
					abilities.splice(i, 1);
					if (save)
					{
						shellApi.profileManager.save();
					}
					break;
				}					
			}
			syncAbilities();
		}

		/**
		 * Remove special ability from Entity, if entity is player then remove special ability from profile as well.
		 * @param charEntity - Entity to remove special ability from
		 * @param param id ability id
		 */
		public function removeSpecialAbility(charEntity:Entity, id:String):void
		{
			CharUtils.removeSpecialAbilityById(charEntity, id);
			
			// if entity is player, remove special ability from profile
			if( charEntity.has(Player) )
			{
				removeSpecialAbilityFromPlayer(id);
			}
		}
		
		// get ability that starts with name "pets/pop_follower"
		public function getAbility(name:String):SpecialAbilityData
		{
			// iterate through abilities
			var abilities:Array = shellApi.profileManager.active.specialAbilities;
			for(var i:Number = 0 ; i < abilities.length; i++)
			{
				// if ablity matches start of name string
				if (abilities[i].indexOf(name) == 0)
				{
					// get special ability control
					var specialControl:SpecialAbilityControl = shellApi.player.get( SpecialAbilityControl ) as SpecialAbilityControl;
					if ( specialControl )
					{
						// split by "/" and get instantiated special ability by type ("pop_follower");
						var arr:Array = name.split("/");
						return specialControl.getSpecialByType(arr[1]);
					}
				}
			}
			return null;
		}
		public function getAbilityById(name:String, dontTruncate:Boolean = false):SpecialAbilityData
		{
			// iterate through abilities
			var abilities:Array = shellApi.profileManager.active.specialAbilities;
			for(var i:Number = 0 ; i < abilities.length; i++)
			{
				// if ablity matches start of name string
				if (abilities[i].indexOf(name) == 0)
				{
					// get special ability control
					var specialControl:SpecialAbilityControl = shellApi.player.get( SpecialAbilityControl ) as SpecialAbilityControl;
					if ( specialControl )
					{
						// split by "/" and get instantiated special ability by type ("pop_follower");
						if(dontTruncate == false)
						{
							var arr:Array = name.split("/");
							return specialControl.getSpecialById(arr[1]);
						}
						else
						{
							return specialControl.getSpecialById(name);
						}
					}
				}
			}
			return null;
		}
		
		public function restore(specialAbilities:Array):void
		{
			// only restore special abilites if player has been created
			// TODO :: Probably also want to check if player is a Poptropican (not a ship)
			if( shellApi.player )	
			{
				for(var i:int = 0 ; i < specialAbilities.length; i++)
				{	
					addSpecialAbilityById(shellApi.player, specialAbilities[i], true);
				}
			}
		}
		
		private function syncAbilities():void
		{
			if (shellApi.needToStoreOnServer())
			{
				var profileManager:ProfileManager = shellApi.profileManager;
				shellApi.siteProxy.store(DataStoreRequest.userFieldStorageRequest('specialAbilities', profileManager.active.specialAbilities, null));
				
				if (PlatformUtils.inBrowser)
				{
					var as2Char:SharedObject = ProxyUtils.getAS2LSO('Char');
					as2Char.data.userData.specialAbilities = profileManager.active.specialAbilities;
				}
			}
		}
	}
}