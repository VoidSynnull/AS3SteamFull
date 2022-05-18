package game.data.specialAbility.character
{
	import com.greensock.easing.Linear;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.group.DisplayGroup;
	import engine.util.Command;
	
	import game.components.entity.character.CharacterWander;
	import game.components.scene.SceneInteraction;
	import game.util.CharUtils;
	import game.util.ColorUtil;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class TurnNpcToStone extends MessWithNpcPower
	{
		override protected function messWithNpc(npc:Entity):void
		{
			var disp:DisplayObjectContainer = EntityUtils.getDisplayObject(npc);
			
			var wander:CharacterWander = npc.get(CharacterWander);
			if(wander)
				wander.pause = true;// this apparentally means didally squat
			//lock that char and hide it
			if(npc == shellApi.player)
				CharUtils.lockControls(npc);
			else
				EntityUtils.lockSceneInteraction(npc);
			
			EntityUtils.visible(npc, false);
			
			var original:Sprite = DisplayGroup(group).createBitmapSprite(disp, PerformanceUtils.defaultBitmapQuality,null, true, 0, null,false);
			disp.filters = [ColorUtil.grayScaleMatrixFilter(.5)];
			var grayScale:Sprite = DisplayGroup(group).createBitmapSprite(disp, PerformanceUtils.defaultBitmapQuality,null, true, 0, null,false);
			disp.filters = [];
			
			original.x = grayScale.x = disp.x;
			original.y = grayScale.y = disp.y;
			var cover:Entity = EntityUtils.createSpatialEntity(group, original, disp.parent).add(new Id("cover"));
			var stone:Entity = EntityUtils.createSpatialEntity(group, grayScale, disp.parent).add(new Id("stone"));
			
			TweenUtils.entityFromTo(stone, Display, 3,{alpha:0}, {alpha:1, onComplete:Command.create(turnedToStone, npc, cover, stone), ease:Linear.easeNone});
			
			super.messWithNpc(npc);
		}
		
		private function turnedToStone(npc:Entity, cover:Entity, stone:Entity):void
		{
			SceneUtil.delay(this, 3, Command.create(revitalizeNpc, npc, cover, stone));
		}
		
		private function revitalizeNpc(npc:Entity, cover:Entity, stone:Entity):void
		{
			var wander:CharacterWander = npc.get(CharacterWander);
			if(wander)
				wander.pause = false;
			
			if(npc == shellApi.player)
				CharUtils.lockControls(npc, false, false);
			else
			{
				SceneInteraction(npc.get(SceneInteraction)).activated = false;
				EntityUtils.lockSceneInteraction(npc, false);
			}
			
			EntityUtils.visible(npc, true);
			removeEntity(cover);
			removeEntity(stone);
		}
	}
}