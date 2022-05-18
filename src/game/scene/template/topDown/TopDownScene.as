package game.scene.template.topDown
{
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.components.animation.procedural.PerspectiveAnimation;
	import game.data.animation.procedural.PerspectiveAnimationLayerParser;
	import game.data.vehicle.VehicleData;
	import game.scene.template.AudioGroup;
	import game.scene.template.GameScene;
	import game.scene.template.VehicleGroup;
	import game.systems.hit.SceneObjectHitCircleSystem;
	
	public class TopDownScene extends GameScene
	{
		public function TopDownScene()
		{
			super();
		}
		
		override protected function addGroups():void
		{
			super.addGroups();
			
			//(super.getGroupById( Hud.GROUP_ID ) as Hud).disableButton( Hud.COSTUMIZER );
			_vehicleGroup = new VehicleGroup();
			super.addChildGroup(_vehicleGroup);
			_vehicleGroup.setupScene(this, super.hitContainer, super.getGroupById(AudioGroup.GROUP_ID) as AudioGroup);
			_vehicleGroup.allVehiclesLoaded.addOnce(allVehiclesLoaded);
			_vehicleGroup.vehicleLoaded.add(vehicleLoaded);
			
			// for collisions between vehicles.
			super.addSystem(new SceneObjectHitCircleSystem());
		}
		
		protected function loadVehicle(data:VehicleData):void
		{
			_vehicleGroup.createVehicle(data);
		}
		
		protected function loadVehicleFromTemplateId(templateId:String, x:Number = NaN, y:Number = NaN, id:String = null):void
		{
			_vehicleGroup.createVehicleFromTemplateId(templateId, x, y, id);
		}
		
		protected function vehicleLoaded(entity:Entity):void
		{
			// override me
		}
		
		protected function allVehiclesLoaded():void
		{
			super.setTarget(super.getEntityById("player"));
		}
		
		protected function addPerspectiveAnimation(entity:Entity, url:String, baseStep:Number = 0.05):void
		{
			var display:Display = entity.get(Display);
			var parser:PerspectiveAnimationLayerParser = new PerspectiveAnimationLayerParser();
			var perspectiveAnimation:PerspectiveAnimation = new PerspectiveAnimation();
			perspectiveAnimation.baseStep = baseStep;
			perspectiveAnimation.layers = parser.parse(super.getData(url), display.displayObject);
			
			entity.add(perspectiveAnimation);
		}
		
		protected var _vehicleGroup:VehicleGroup;
	}
}