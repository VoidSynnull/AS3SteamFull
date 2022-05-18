package game.systems.specialAbility.character
{
	import flash.display.Sprite;
	import flash.geom.Matrix;
	
	import ash.core.Entity;
	
	import engine.group.DisplayGroup;
	
	import game.components.input.Input;
	import game.components.specialAbility.character.FlashlightEffect;
	import game.scenes.carnival.CarnivalEvents;
	import game.nodes.specialAbility.character.FlashlightEffectNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.SkinUtils;
	
	public class FlashlightEffectSystem extends GameSystem
	{
		private var _input:Input;
		private var _group:DisplayGroup;
		//private var _haveFlashlight:Boolean = false;
		private var carnivalEvents:CarnivalEvents;
		private var player:Entity;
		
		public function FlashlightEffectSystem(group:DisplayGroup)
		{
			super( FlashlightEffectNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
			
			_group = group;
			_input = Input(_group.shellApi.inputEntity.get(Input));
			//if (group.shellApi.checkItem(carnivalEvents.FLASHLIGHT) || group.shellApi.checkItem(carnivalEvents.FLASHLIGHT_BLACK)) {
				//_haveFlashlight = true;
			//}
			
			player = group.shellApi.player;
		}
		
		// Currently ignoring time as this is just a visual effect
		private function updateNode( node:FlashlightEffectNode, time:Number):void
		{
			var clip:Sprite = node.display.displayObject as Sprite;
			var fe:FlashlightEffect = node.flashlightEffect;
			var itemString:String = SkinUtils.getSkinPart(player, SkinUtils.ITEM).value;
			
			clip.graphics.clear();
			clip.graphics.beginFill(0x000000, fe.darkAlpha);
			clip.graphics.drawRect(0, 0, _group.shellApi.viewportWidth, _group.shellApi.viewportHeight);
			if (itemString == "mc_flashlight_normal" || itemString == "mc_flashlight_black") {
				clip.graphics.drawCircle(_input.target.x, _input.target.y, fe.lightRadius);
				
				var matr:Matrix = new Matrix();
				matr.createGradientBox(fe.lightRadius*2, fe.lightRadius*2, 0, _input.target.x - fe.lightRadius, _input.target.y - fe.lightRadius);
				if (itemString == "mc_flashlight_black") {
					clip.graphics.beginGradientFill("radial", [0x6409AE, 0x000000], [0, fe.darkAlpha], [0, 255], matr);
				}
				else {
					clip.graphics.beginGradientFill("radial", [0x000000, 0x000000], [0, fe.darkAlpha], [0, 255], matr);
				}
				clip.graphics.drawCircle(_input.target.x, _input.target.y, fe.lightRadius);
			}
			clip.graphics.endFill();
		}
	}
}