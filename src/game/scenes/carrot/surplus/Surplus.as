package game.scenes.carrot.surplus
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.entity.Dialog;
	import game.components.motion.TargetEntity;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scene.template.PhotoGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.carrot.CarrotEvents;
	import game.util.CharUtils;
	import game.util.SceneUtil;
	
	public class Surplus extends PlatformerGameScene
	{
		public function Surplus()
		{
			super();
		}
		
		override public function destroy():void	
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/carrot/surplus/";
			
			super.init(container);
		}
				
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = super.events as CarrotEvents;
			
			if( super.shellApi.checkEvent( _events.CAT_FOLLOWING ))
			{
				var cat:Entity = super.groupManager.getEntityById("cat", this);
				cat.get(Spatial).x = shellApi.player.get(Spatial).x;
				cat.get(Spatial).y = shellApi.player.get(Spatial).y;
				ToolTipCreator.removeFromEntity(cat);
				
				CharUtils.followEntity( cat, shellApi.player, new Point(300, 200) );
				SceneUtil.lockInput(this, true);
				CharUtils.moveToTarget( super.player, 650, 653, true, presentCat );
			}
			
			var bell:Entity = super.getEntityById( "interaction" );
			ToolTipCreator.removeFromEntity(bell);
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( bell );
			
			SceneInteraction( bell.get(SceneInteraction) ).reached.add( sceneInteractionTriggered );
		}
	
		private function presentCat( entity:Entity ):void 
		{
			CharUtils.lockControls( super.player, true );
			
			Dialog( super.player.get( Dialog )).sayById( "present_cat" );
			Dialog( super.player.get( Dialog )).complete.addOnce( acceptCat );
		}
		
		private function acceptCat( dialogData:DialogData ):void
		{
			var owner:Entity = super.getEntityById( "owner" );
			
			Dialog( owner.get( Dialog )).sayById( "cat_following" );
			Dialog( owner.get( Dialog )).complete.addOnce( ownerDialogComplete );
		}
		
		private function ownerDialogComplete( dialogData:DialogData ):void
		{
			if(dialogData.triggerEvent.args[0] == _events.CAT_RETURNED )
			{
				// take photo, if PhotoGroup exists
				var photoGroup:PhotoGroup =  super.getGroupById(PhotoGroup.GROUP_ID) as PhotoGroup;
				if( photoGroup )
				{
					photoGroup.takePhotoByEvent(_events.CAT_RETURNED);
				}

				super.shellApi.eventTriggered.add( onEventTriggered );
				catFollowOwner();
				
				var owner:Entity = super.getEntityById("owner");
				Dialog( owner.get( Dialog )).complete.removeAll();
				// manually update the dialog so the other 'cat returned' stuff doesn't happen until we're next in this scene.
				Dialog( owner.get( Dialog )).eventTriggered(_events.CAT_RETURNED);
			}
		}
		
		private function sceneInteractionTriggered( character:Entity, interaction:Entity ):void
		{
			super.shellApi.triggerEvent( _events.BELL_RING );
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == GameEvent.GOT_ITEM + _events.CROWBAR )
			{
				CharUtils.lockControls( super.player, false, false );
				SceneUtil.lockInput(this, false, false);
			}
		}
		
		private function catFollowOwner():void
		{
			var cat:Entity = super.groupManager.getEntityById("cat", this);
			//TargetEntity( cat.get( TargetEntity )).active = false;
			cat.remove( TargetEntity );

			var owner:Entity = super.groupManager.getEntityById("owner", this);
			var ownerSpatial:Spatial = owner.get(Spatial);
			
			CharUtils.moveToTarget(cat, ownerSpatial.x + 100, ownerSpatial.y, true).setDirectionOnReached( "", ownerSpatial.x );
		}
		
		private var _events:CarrotEvents;
	}
}