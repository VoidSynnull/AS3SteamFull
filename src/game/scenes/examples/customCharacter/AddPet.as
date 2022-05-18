package game.scenes.examples.customCharacter
{
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.motion.TargetEntity;
	import game.data.specialAbility.SpecialAbility;
	import game.nodes.specialAbility.SpecialAbilityNode;
	import game.scene.template.PlatformerGameScene;
	
	public class AddPet extends SpecialAbility
	{
		public function AddPet()
		{
			super();
		}
		
		// doesn't seem to get called.
		override public function deactivate( node:SpecialAbilityNode ):void
		{
			if(_pet)
			{
				super.group.removeEntity(_pet);
				_pet = null;
				super.setActive(false);
			}
		}
		
		// On activate, load the file passed in as a param
		override public function activate( node:SpecialAbilityNode ):void
		{
			if(super.data.isActive)
			{
				deactivate(node);
			}
			else 
			{
				super.setActive(true);
				var spatial:Spatial = super.entity.get(Spatial);
				createCustomCharacter(spatial.x, spatial.y, "playerPet");
			}
		}
		
		private function createCustomCharacter(x:Number, y:Number, id:String = null, target:Spatial = null):void
		{
			super.shellApi.loadFile(super.shellApi.assetPrefix + super.data.params.getParamId("assetPath").value, customCharacterLoaded, x, y, id, target);
		}
		
		private function customCharacterLoaded(clip:MovieClip, x:Number, y:Number, id:String = null, target:Spatial = null):void
		{
			var scene:PlatformerGameScene = super.group as PlatformerGameScene;
			
			// only for platformer scenes 
			if(scene != null)
			{
				var customCharacterCreator:CustomCharacterCreator = new CustomCharacterCreator();
				
				_pet = customCharacterCreator.create(scene, scene.hitContainer, clip, x, y, target, false, id, null, true);
				
				scene.addEntity(_pet);
							
				var targetEntity:TargetEntity = _pet.get(TargetEntity);
				targetEntity.target = super.entity.get(Spatial);
				var motionControl:CharacterMotionControl = _pet.get(CharacterMotionControl);
				// determines closeness of follow.  Props should be renamed to better describe purpose in CharacterMovementSystem.
				motionControl.inputDeadzoneX = 150;
				motionControl.inputDeadzoneY = 100;
			}
		}
				
		private var _pet:Entity;
	}
}