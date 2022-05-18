package game.scenes.virusHunter.shared
{
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.entity.Sleep;
	import game.components.hit.CurrentHit;
	import game.components.motion.TargetEntity;
	import game.components.hit.Platform;
	import game.data.ui.ToolTipType;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	
	public class DualScene extends PlatformerGameScene
	{
		public function DualScene()
		{
			super();
		}

		override public function loaded():void
		{
			super.loaded();
		}
		
		// all assets ready
		private function setupShipGroup():void
		{
			_shipGroup = new ShipGroup();
			_shipGroup.setupScene(this, super._hitContainer, allShipsLoaded, super.getGroupById("audioGroup") as AudioGroup);
			
			var spatial:Spatial = super.shellApi.player.get(Spatial);
			
			loadPlayerShip(spatial.x, spatial.y);
		}
		
		override protected function allCharactersLoaded():void
		{
			super.allCharactersLoaded();
			
			var playerSpatial:Spatial = player.get(Spatial) as Spatial;
			playerSpatial.scale *= .5;
			
			setupShipGroup();
		}
		
		protected function allShipsLoaded():void
		{
			// set the camera to use the new target entity's Spatial as its target.
			_cameraGroup = super.getGroupById("cameraGroup") as CameraGroup;
			
			// use the target entity's motion to set the zoom level.
			_cameraGroup.setZoomByMotionTarget(super.shellApi.player.get(Motion), 1.25, .75);
			
			var ship:Entity = super.getEntityById("playerShip");
			MotionUtils.followInputEntity(ship, super.shellApi.inputEntity, true);
			TargetEntity(ship.get(TargetEntity)).active = false;
			MotionControl(ship.get(MotionControl)).lockInput = true;
			var interaction:Interaction = ship.get(Interaction);
			InteractionCreator.addToComponent(ship.get(Display).displayObject, [InteractionCreator.CLICK], interaction);
			interaction.click.add(shipClicked);
			
			super._hitContainer.swapChildren(Display(super.shellApi.player.get(Display)).displayObject, Display(ship.get(Display)).displayObject);
			
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			
			loaded();
		}
		
		
		
		private function loadPlayerShip(x:Number, y:Number):void
		{
			_shipGroup.loadShip(x, y, true, "playerShip");
		}
		
		private function shipClicked(ship:Entity):void
		{
			var playerSleep:Sleep = super.player.get(Sleep);
			var shipMotionControl:MotionControl = ship.get(MotionControl);
			
			if(shipMotionControl.lockInput)
			{
				var spatial:Spatial = ship.get(Spatial);
				var interactorSpatial:Spatial = super.player.get(Spatial);
				var targetX:Number = spatial.x;
				var targetY:Number = spatial.y;
				var targetDirectionX:Number = spatial.x;
				var targetDirectionY:Number = spatial.x;
				
				if (interactorSpatial.x < spatial.x)
				{
					targetX = spatial.x - 100;
				}
				
				targetDirectionX = targetX;
				targetDirectionY = targetY;
				
				CharUtils.moveToTarget(super.player, targetX, targetY, false, Command.create(enterShip, ship) ).setDirectionOnReached( "", targetDirectionX, targetDirectionY);
			}
			else if(playerSleep.sleeping)
			{				
				if(Spatial(ship.get(Spatial)).y >= super.sceneData.bounds.height - 100)
				{
					exitShip(ship);
				}
				else if(CurrentHit(ship.get(CurrentHit)).hit != null)
				{
					if(CurrentHit(ship.get(CurrentHit)).hit.get(Platform) != null)
					{
						exitShip(ship);
					}
				}
				
			}
		}
		
		private function exitShip(ship:Entity):void
		{
			var playerSleep:Sleep = super.player.get(Sleep);
			var shipMotionControl:MotionControl = ship.get(MotionControl);
			
			super.player.get(Spatial).x = ship.get(Spatial).x;
			super.player.get(Spatial).y = ship.get(Spatial).y - Edge(super.player.get(Edge)).rectangle.bottom;
			playerSleep.sleeping = false;
			shipMotionControl.lockInput = true;
			_cameraGroup.target = super.player.get(Spatial);
			//_cameraGroup.setZoomByMotionTarget(super.shellApi.player.get(Motion), 1.25, .75);
			
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}
		
		private function enterShip(player:Entity, ship:Entity):void
		{
			var playerSleep:Sleep = super.player.get(Sleep);
			var shipMotionControl:MotionControl = ship.get(MotionControl);
			
			playerSleep.sleeping = true;
			shipMotionControl.lockInput = false;
			_cameraGroup.target = ship.get(Spatial);
			//_cameraGroup.setZoomByMotionTarget(ship.get(Motion), .75, .5);
			
			super.shellApi.defaultCursor = ToolTipType.TARGET;
			ship.get(Display).alpha = .3;
		}
		
		private var _cameraGroup:CameraGroup;
		private var _shipGroup:ShipGroup
	}
}