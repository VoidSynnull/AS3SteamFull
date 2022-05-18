package game.scenes.carnival.ridesNight.systems 
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.entity.collider.HazardCollider;
	import game.data.animation.entity.character.Jump;
	import game.scenes.carnival.ridesNight.RidesNight;
	import game.scenes.carnival.ridesNight.nodes.StrengthMonsterNode;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.util.CharUtils;
	
	public class StrengthMonsterSystem extends System
	{
		private var _strengthMonsters:NodeList;
		private var player:Entity;
		private var monster:StrengthMonsterNode;
		private var mSpatial:Spatial;
		private var mTimeline:Timeline;
		private var pSpatial:Spatial;
				
		public function StrengthMonsterSystem()
		{
			super._defaultPriority = SystemPriorities.update;
		}
		
		override public function addToEngine( systemsManager:Engine ):void
		{
			_strengthMonsters = systemManager.getNodeList( StrengthMonsterNode );
			monster = _strengthMonsters.head;
			player = RidesNight(super.group).player;
			mSpatial = monster.entity.get(Spatial);
			mTimeline = monster.entity.get(Timeline);
			pSpatial = RidesNight(super.group).player.get(Spatial);
			
			mTimeline.handleLabel("whackHit", hitPlayer, false);
			mTimeline.handleLabel("whackHighHit", hitPlayerHigh, false);
		}
		
		override public function update( time:Number ):void
		{
			if(mSpatial.x > pSpatial.x){
				mSpatial.scaleX = 1;
			}else{
				mSpatial.scaleX = -1;
			}
			
			if(Math.abs(mSpatial.x - pSpatial.x) < 230){
				if(mTimeline.currentIndex < 52){ 
					if(pSpatial.y > mSpatial.y){
						mTimeline.gotoAndPlay("whack");
					}else{
						mTimeline.gotoAndPlay("whackhigh");
					}
					RidesNight(super.group).shellApi.triggerEvent("monsterSound");
				}
			}
		}
		
		private function hitPlayer():void {
			if(Math.abs(mSpatial.x - pSpatial.x) < 220 && Math.abs(mSpatial.y - pSpatial.y) < 150){
					CharUtils.setState(player, CharacterState.JUMP);
					var collider:HazardCollider = player.get(HazardCollider);
					if(mSpatial.x > pSpatial.x){
						collider.velocity = new Point(-1150, -900);
					}else{
						collider.velocity = new Point(1150, -900);
					}
					CharUtils.setState(player, CharacterState.HURT);
			}
		}
		
		private function hitPlayerHigh():void {
			if(Math.abs(mSpatial.x - pSpatial.x) < 220 && Math.abs(mSpatial.y - pSpatial.y) < 200){
				CharUtils.setState(player, CharacterState.JUMP);
				var collider:HazardCollider = player.get(HazardCollider);
				if(mSpatial.x > pSpatial.x){
					collider.velocity = new Point(-1150, -900);
				}else{
					collider.velocity = new Point(1150, -900);
				}
				CharUtils.setState(player, CharacterState.HURT);
			}
		}
		
		override public function removeFromEngine( systemsManager:Engine ):void
		{
			systemsManager.releaseNodeList( StrengthMonsterNode );
			_strengthMonsters = null;
		}
	}
}




