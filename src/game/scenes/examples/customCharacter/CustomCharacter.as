package game.scenes.examples.customCharacter
{
	import game.components.specialAbility.SpecialAbilityControl;
	import game.data.TimedEvent;
	import game.data.specialAbility.SpecialAbilityData;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class CustomCharacter extends PlatformerGameScene
	{
		public function CustomCharacter()
		{
			super();
		}
				
		// initiate asset load of scene specific assets.
		override public function loaded():void
		{
			var specialData:SpecialAbilityData = new SpecialAbilityData(AddPet);
			specialData.params.addParam("assetPath", "scenes/examples/customCharacter/bot.swf");  // ?!?!?!?!?!
			CharUtils.addSpecialAbility(super.player, specialData);
			
			SceneUtil.addTimedEvent(this, new TimedEvent(.5, 1, handleActivate));
			
			super.loaded();
		}
		
		private function handleActivate():void
		{
			var control:SpecialAbilityControl = super.player.get(SpecialAbilityControl);
			control.trigger = true;
		}
	}
}