package game.creators.scene
{
	import com.poptropica.AppConfig;
	import com.smartfoxserver.v2.entities.User;
	import com.smartfoxserver.v2.entities.data.ISFSObject;
	import com.smartfoxserver.v2.entities.variables.UserVariable;
	
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.render.PlatformDepthCollider;
	import game.components.smartFox.SFScenePlayer;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.managers.SmartFoxManager;
	import game.managers.SpecialAbilityManager;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.SFSceneGroup;
	import game.util.EntityUtils;

	public class SFSceneEntityCreator
	{
		public function SFSceneEntityCreator()
		{
			_lookConverter = new LookConverter();
		}
		
		/**
		 * 
		 * @param $scene
		 * @param $user
		 * @param $addToEntity
		 * @param $sfPlayerState
		 * @param onComplete - Function called once character entity finished creayion process, calls with params [ Entity ]
		 * @return 
		 * 
		 */
		public function createSFPlayerEntity($scene:GameScene, $user:User, $addToEntity:Entity = null, $sfPlayerState:ISFSObject = null, onComplete:Function = null):Entity{
			
			if(AppConfig.debug){
				trace("   ----------------------------------");
				trace("   [ ... Creating SFSceneEntity ... ]");
				trace("   ----------------------------------");
			}
			
			// 
			if (SFSceneGroup.DEBUG){
				var debugSprite:Sprite = new Sprite();
				debugSprite.mouseEnabled = false;
				debugSprite.mouseChildren = false;
				debugSprite.graphics.clear();
				if($user.isItMe){
					debugSprite.graphics.beginFill(0x33CCFF, 0.7);
				} else {
					debugSprite.graphics.beginFill(0x66FF99, 0.7);
				}
				debugSprite.graphics.drawCircle(0,0,30);
				
				$scene.hitContainer.addChild(debugSprite);
				
				var spatial_debug:Entity = EntityUtils.createMovingEntity($scene, debugSprite, $scene.hitContainer);
			}
			
			var charGroup:CharacterGroup = $scene.getGroupById(CharacterGroup.GROUP_ID) as CharacterGroup;
			
			// get user look from the user's look variable
			var user_look_var:UserVariable = $user.getVariable(SFSceneGroup.USER_CHAR_LOOK);
			var lookData:LookData = _lookConverter.lookDataFromLookString(user_look_var.getStringValue());
			
			var data:Object = {};
			data.scene = $scene;
			var user_abilities_var:UserVariable = $user.getVariable(SmartFoxManager.USER_CHAR_ABILITIES);
			if(user_abilities_var){
				trace("SFSceneEntityCreator :: createSFPlayerEntity  - abilities added: " + user_abilities_var.getStringValue());
				// assemble array of special ability ids
				var abilities:Array = user_abilities_var.getStringValue().split(",");
				data.abilities = abilities;
			}
			
			var entity:Entity = charGroup.createNpc($user.name, lookData, 0,0, "right", "", null, Command.create(npcLoaded, data, onComplete));

			// Add component containing SFS user specifics
			var sfScenePlayer:SFScenePlayer = new SFScenePlayer($user);
			sfScenePlayer.state_obj = $sfPlayerState;
			if(SFSceneGroup.DEBUG){
				sfScenePlayer.spatial_debug = spatial_debug;
			}
			entity.add(sfScenePlayer);
			
			// add player carrot
			/*if(!$user.isItMe || SFSceneGroup.DEBUG){
				var carrots:PlayerCarrots = $scene.getGroupById(PlayerCarrots.GROUP_ID) as PlayerCarrots;
				carrots.addCarrotTo(entity);
			}*/
			
			return entity;
		}
		
		private function npcLoaded( charEntity:Entity, data:Object, onComplete:Function = null ):void
		{
			var sfScenePlayer:SFScenePlayer = charEntity.get(SFScenePlayer);
			var user:User = sfScenePlayer.user;
			
			// if not your player then disable sleep (DEBUG mode will show your player as well) 
			if(!user.isItMe || SFSceneGroup.DEBUG){
				// if not you or debug mode
				Sleep(charEntity.get(Sleep)).sleeping = false;
				Sleep(charEntity.get(Sleep)).ignoreOffscreenSleep = true;
			} else {
				// is your player && not debug mode then disable
				// TODO :: Probably a cleaner way to disable this entity. - bard
				Sleep(charEntity.get(Sleep)).sleeping = true;
				Sleep(charEntity.get(Sleep)).ignoreOffscreenSleep = true;
				Character(charEntity.get(Character)).costumizable = false;
			}
			
			// setup player abilities

			if(data.abilities){
				var specialAbilityManager:SpecialAbilityManager = GameScene(data.scene).shellApi.getManager(SpecialAbilityManager) as SpecialAbilityManager;
				//specialAbilityManager.addSpecialAbilityById(charEntity, "electro_power_blue");  /// test
				
				for each(var ability_id:String in data.abilities as Array){
					specialAbilityManager.addSpecialAbilityById(charEntity, ability_id);
				}
			}
			
			// setup player functions in SFSceneGroup
			if( onComplete != null ) {  onComplete(charEntity) };
			
			// set depth priority to be behind NPCs (so they don't block)
			charEntity.add(new PlatformDepthCollider(-1));
			
			if(AppConfig.debug){
				trace("   ---------------------------------");
				trace("   [ ... SFSceneEntity Created ... ]");
				trace("   ---------------------------------");
			}
		}
		
		public function createSFObjectEntity($group:Group, $addToEntity:Entity = null):Entity{
			return new Entity();
		}
		
		private var _lookConverter:LookConverter;
	}
}