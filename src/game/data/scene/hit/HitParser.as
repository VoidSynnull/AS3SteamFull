/**
 * Parses XML with scene data.
 */

package game.data.scene.hit
{	
	import flash.utils.Dictionary;
	
	import game.data.scene.hit.RadialHitData;
	import game.util.DataUtils;
	import game.data.scene.hit.LooperHitParser;
	
	public class HitParser
	{			
		/**
		 * Parses hit.xml into Dictionary of HitData, with HitData.id as key
		 */
		public function parse(xml:XML):Dictionary
		{		
			var data:Dictionary = new Dictionary(true);
			var id:String;
			var hits:XMLList = xml.children() as XMLList;
			var hitComponents:XMLList;
			var hitXML:XML;
			var hitData:HitData;
			var hitDataComponent:HitDataComponent;
			var color:uint;
						
			for (var i:uint = 0; i < hits.length(); i++)
			{	
				hitXML = hits[i];
				
				hitData = new HitData();
				hitData.id = DataUtils.getString(hitXML.attribute("id"));
				hitData.color = DataUtils.getUint(hitXML.attribute("color"));
				hitData.platform = DataUtils.getBoolean(hitXML.attribute("platform"));
				hitData.components = new Dictionary();
				hitData.wrapX = DataUtils.getUint(hitXML.attribute("wrapX"));
				
				hitComponents = hitXML.children() as XMLList;
				
				for (var n:uint = 0; n < hitComponents.length(); n++)
				{
					hitDataComponent = parseHit(hitComponents[n] as XML, hitData.id);
					hitData.components[hitDataComponent.type] = hitDataComponent;
				}
				
				data[hitData.id] = hitData;
			}

			return(data);
		}
		
		public function parseHit(xml:XML, id:String):HitDataComponent
		{	
			var type:String = DataUtils.getString(xml.attribute("type"));			
			var hitDataComponent:HitDataComponent;

			switch(type)
			{					
				case HitType.WATER :
					if(_waterHitParser == null)
					{
						_waterHitParser = new WaterHitParser();
					}
					hitDataComponent = _waterHitParser.parse(xml);
					break;
				
				case HitType.PLATFORM_REBOUND :
				case HitType.PLATFORM :
				case HitType.PLATFORM_TOP :
				case HitType.MOVER :
				case HitType.BOUNCE :
					if(_moverHitParser == null)
					{
						_moverHitParser = new MoverHitParser();
					}
					hitDataComponent = _moverHitParser.parse(xml);
					break;
				
				case HitType.MOVING_PLATFORM :
				case HitType.MOVING_HIT :
					if(_movingHitParser == null)
					{
						_movingHitParser = new MovingHitParser();
					}
					hitDataComponent = _movingHitParser.parse(xml);
					break;
				
				case HitType.HAZARD :
					if(_hazardHitParser == null)
					{
						_hazardHitParser = new HazardHitParser();
					}
					hitDataComponent = _hazardHitParser.parse(xml);	
					break;
				
				case HitType.RADIAL :
					hitDataComponent = new RadialHitData();
					
					if(xml.hasOwnProperty("rebound"))
					{
						RadialHitData(hitDataComponent).rebound = DataUtils.getNumber(xml.rebound);
					}
					break;
				
				case HitType.WIRE_BOUNCE:
					if(_bounceWireParser == null)
					{
						_bounceWireParser = new BounceWireParser();
					}
					hitDataComponent = _bounceWireParser.parse(xml);
					
					break;
				
				case HitType.LOOPER:
					if( _looperHitParser == null )
					{
						_looperHitParser = new LooperHitParser();
					}
					hitDataComponent = _looperHitParser.parse( xml );
					
					break;
				
				case HitType.EMITTER:
					if( _emitterHitParser == null )
					{
						_emitterHitParser = new EmitterHitParser();
					}
					hitDataComponent = _emitterHitParser.parse( xml );
					
					break;
				
				default:
					hitDataComponent = new HitDataComponent();
					break;
			}
			hitDataComponent.xml = xml;
			hitDataComponent.visibles = DataUtils.useArray( xml.visibles, null );
			hitDataComponent.visible = DataUtils.getString(xml.visible);
			hitDataComponent.followProperties = DataUtils.useArray(xml.visible.attribute("followProperties"), null);
			hitDataComponent.type = type;
			
			return(hitDataComponent);
		}
		
		private var _bounceWireParser:BounceWireParser;
		private var _movingHitParser:MovingHitParser;
		private var _hazardHitParser:HazardHitParser;
		private var _moverHitParser:MoverHitParser;
		private var _waterHitParser:WaterHitParser;
		private var _looperHitParser:LooperHitParser;
		private var _emitterHitParser:EmitterHitParser;
	}
}