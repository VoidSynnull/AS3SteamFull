package game.scene.template
{
	import com.poptropica.Assert;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	
	import game.creators.scene.VehicleCreator;
	import game.data.vehicle.VehicleData;
	import game.managers.TemplateManager;
	import game.systems.SystemPriorities;
	import game.systems.animation.procedural.PerspectiveAnimationSystem;
	import game.systems.input.MotionControlInputMapSystem;
	import game.systems.motion.AccelerateToTargetRotationSystem;
	import game.systems.motion.DestinationSystem;
	import game.systems.motion.MotionControlBaseSystem;
	import game.systems.motion.MotionTargetSystem;
	import game.systems.motion.MoveToTargetSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.RotateToTargetSystem;
	import game.systems.motion.TargetEntitySystem;
	import game.systems.motion.VehicleMotionSystem;
	import game.util.EntityUtils;
	
	import org.osflash.signals.Signal;
	
	public class VehicleGroup extends Group
	{
		public function VehicleGroup()
		{
			super();
			super.id = GROUP_ID;
		}
		
		public function setupScene(scene:Scene, container:DisplayObjectContainer, audioGroup:AudioGroup):void
		{
			_targetGroup = scene;
			_container = container;
			_vehicleCreator = new VehicleCreator(audioGroup);
			
			var templates:XML = scene.getData("templates.xml");
			
			if(templates != null)
			{
				_templateManager = new TemplateManager();
				_templateManager.init(_targetGroup, templates);
			}
			
			scene.addSystem(new VehicleMotionSystem(), SystemPriorities.moveComplete);
			scene.addSystem(new RotateToTargetSystem(), SystemPriorities.move);
			scene.addSystem(new MoveToTargetSystem(super.shellApi.viewportWidth, super.shellApi.viewportHeight), SystemPriorities.moveControl);  // maps control input position to motion components.
			scene.addSystem(new MotionControlInputMapSystem(), SystemPriorities.update);    // maps input button presses to acceleration.
			scene.addSystem(new MotionTargetSystem(), SystemPriorities.move);
			scene.addSystem(new MotionControlBaseSystem(), SystemPriorities.move);
			scene.addSystem(new AccelerateToTargetRotationSystem(), SystemPriorities.move);
			scene.addSystem(new NavigationSystem(), SystemPriorities.update);			    // This system moves an entity through a series of points for autopilot.
			scene.addSystem(new DestinationSystem(), SystemPriorities.update);	
			scene.addSystem(new TargetEntitySystem(), SystemPriorities.update);
			scene.addSystem(new PerspectiveAnimationSystem(), SystemPriorities.updateAnim);

			this.vehicleLoaded = new Signal(Entity);
			this.allVehiclesLoaded = new Signal();
		}
		
		public function createVehicleFromTemplateId(templateId:String, x:Number = NaN, y:Number = NaN, id:String = null):Entity
		{
			if(_templateManager != null)
			{
				var entity:Entity = _templateManager.makeFromTemplates(templateId, _container, assetLoaded);
	
				if(!isNaN(x) && !isNaN(y))
				{
					entity.add(new Spatial(x, y));
				}
				
				if(id != null)
				{
					entity.add(new Id(id));
				}
				
				_loading++;
				
				return(entity);
			}
			else
			{
				Assert.error("Template Manager is null!");
				return(null);
			}
		}
		
		public function createVehicle(data:VehicleData):Entity
		{
			var entity:Entity;
			
			entity = _vehicleCreator.createFromVehicleData(_container, _targetGroup.sceneData.bounds, data);
			
			_targetGroup.addEntity(entity);
			
			EntityUtils.loadAndSetToDisplay(_container, data.url, entity, _targetGroup, assetLoaded, true);
						
			_loading++;
			
			return(entity);
		}
		
		private function assetLoaded(clip:MovieClip, entity:Entity):void
		{
			this.vehicleLoaded.dispatch(entity);
			
			_loading--;
			
			if(_loading == 0)
			{
				allLoaded();
			}
		}
		
		private function allLoaded():void
		{
			this.allVehiclesLoaded.dispatch();
		}
		
		public static const GROUP_ID:String = "vehicleGroup";
		public var allVehiclesLoaded:Signal;
		public var vehicleLoaded:Signal;
		private var _loading:int = 0;
		private var _vehicleCreator:VehicleCreator;
		private var _container:DisplayObjectContainer;
		private var _targetGroup:Scene;
		private var _templateManager:TemplateManager;
	}
}