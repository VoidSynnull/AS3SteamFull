package game.scenes.hub.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.scene.template.NapeGroup;
	
	import nape.callbacks.CbType;
	import nape.phys.Body;
	import nape.phys.BodyType;
	import nape.shape.Polygon;
	import nape.shape.Shape;
	
	public class SnowballPlayer extends Component
	{
		
		public function SnowballPlayer(entity:Entity, napeGroup:NapeGroup, cbType:CbType)
		{
			// create a nape body
			body = new Body(BodyType.DYNAMIC);
			var shape:Shape = new Polygon(Polygon.box(40, 80));
			body.shapes.add(shape);
			body.cbTypes.add(cbType);
			body.userData.entity = entity;
			
			napeGroup.makeNapeCollider(entity, body);
		}
		
		public override function destroy():void
		{
			body.shapes.remove(body.shapes.at(0));
			body.cbTypes.clear();
			body.space = null;
			body.userData.entity = null;
			
			body = null;
			
			super.destroy();
		}
		
		public function duck():void
		{
			body.shapes.remove(body.shapes.at(0));
			var shape:Shape  = new Polygon(Polygon.box(40, 50));
			body.shapes.add(shape);
			ducking = true;
		}
		
		public function reset():void
		{
			body.shapes.remove(body.shapes.at(0));
			var shape:Shape  = new Polygon(Polygon.box(40, 80));
			body.shapes.add(shape);
			ducking = false;
		}
		
		
		public var ducking:Boolean;
		private var body:Body;
	}
}