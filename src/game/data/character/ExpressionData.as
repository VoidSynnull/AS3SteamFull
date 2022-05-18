package game.data.character
{
	import ash.core.Entity;
	
	import game.util.DataUtils;
	import game.util.SkinUtils;
	
	public class ExpressionData
	{
		public var pupilState:*;
		public var lookData:LookData;
		
		public function ExpressionData(xml:XML = null)
		{
			parse(xml);
		}
		
		public function parse(xml:XML):void
		{
			if(xml == null)
				return;
			
			if(xml.hasOwnProperty("pupilState"))
				pupilState = DataUtils.getString(xml.pupilState);
			
			lookData = new LookData(xml);
		}
		
		public function toXML():XML
		{
			var xml:XML = <expression/>;
			if(pupilState != null)
				xml.appendChild(new XML("<pupilState>"+pupilState+"</pupilState>"));
			var property:String;
			for ( var i:int = 0; i < SkinUtils.LOOK_ASPECTS.length; i++)
			{
				property = SkinUtils.LOOK_ASPECTS[i];
				if(DataUtils.validString(lookData.getValue(property)))
					xml.appendChild(new XML("<"+property+">"+lookData.getValue(property)+"</"+property+">"));
			}
			
			return xml;
		}
		
		public function duplicate():ExpressionData
		{
			var expression:ExpressionData = new ExpressionData();
			
			expression.lookData = lookData.duplicate();
			expression.pupilState = pupilState;
			
			return expression;
		}
		
		public function applyExpression(entity:Entity):void
		{
			var appliedLook:LookData = SkinUtils.getLook(entity, true );
			appliedLook.merge( lookData );	// TODO :: allow for non-permanent assignment 
			SkinUtils.applyLook( entity, appliedLook, false );
			
			if(pupilState != null)
			{
				SkinUtils.setEyeStates(entity, appliedLook.getValue(SkinUtils.EYE_STATE), pupilState, false);
			}
		}
	}
}