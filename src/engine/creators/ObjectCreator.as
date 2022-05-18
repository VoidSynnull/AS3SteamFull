package engine.creators
{
	import game.util.ClassUtils;
	import game.util.DataUtils;
	
	/**
	 * ObjectCreator is a small set of functions that creates Object instances dynamically. Given an XML with
	 * the proper formatting, ObjectCreator can create an instance of any Class. These functions work recursively,
	 * so if the Object being created needs Objects within itself, it'll create those Objects along the way.
	 * 
	 * <p>
	 * <b>How-To</b><br/>
	 * <ul>
	 * 		<li>Any XML element with a <code>class</code> attribute is considered an Object.</li>
	 * 		<ul>
	 * 			<li>The <code>class</code> value <b>must</b> be a fully qualified Class name. (Ex. flash.display.Shape)</li>
	 * 			<li>Objects have 2 child elements: <code>constructor</code> and <code>properties</code>.</li>
	 * 			<ul>
	 * 				<li>Any child element of <code>constructor</code> will be assigned to the Object's constructor when it is instantiated.</li>
	 * 				<ul>
	 * 					<li>These elements <b>must</b> to be in the order that the constructor takes them in.</li>
	 * 					<li>The names of the elements are irrelevant, but it's good practice to name them what the Object's constructor calls them for clarity.</li>
	 * 				</ul>
	 * 				<li>Any child element of <code>properties</code> will be assigned to the Object's property or function.</li>
	 * 				<ul>
	 * 					<li>These elements don't need to be in any order unless needed. (Ex. Calling graphics.beginFill() before graphics.drawCircle())</li>
	 * 					<li>The names of the elements <b>must</b> match a property or function of the Object.</li>
	 * 				</ul>
	 * 			</ul>
	 * 			<li>If the element has a <code>constructed</code> attribute that is <code>true</code>, the Object is considered already instantiated. (Ex. DisplayObjects have an already instantiated Graphics property.)</li>
	 * 		</ul>
	 * 		<li>Any XML element with a <code>function</code> attribute is considered a Function.</li>
	 * 		<ul>
	 * 			<li>The <code>function</code> value should be <code>true</code> or <code>false</code>.</li>
	 * 			<li>Functions have 1 child element: <code>constructor</code>, and behave similarly to Object constructors.</li>
	 * 			<ul>
	 * 				<li>Any child element of <code>constructor</code> will be assigned to the Function when it is called.</li>
	 * 				<ul>
	 * 					<li>These elements <b>must</b> to be in the order that the Function takes them in.</li>
	 * 					<li>The names of the elements are irrelevant, but it's good practice to name them what the Function calls them for clarity.</li>
	 * 				</ul>
	 * 			</ul>
	 * 		</ul>
	 * 		<li>Any other XML elements without <code>class</code> or <code>function</code> attributes are considered primitive data types. (Ex. int, Number, Boolean, etc.)</li>
	 * </ul>
	 * 
	 * @author Drew Martin
	 */
	
	/*
	A Brief Example
	
	<displayObject class="flash.display.Shape">
		<properties>
			<x>390</x>
			<y>273</y>
			<graphics class="flash.display.Graphics" constructed="true">
				<properties>
					<lineStyle function="true">
						<thickness>1</thickness>
						<color>0xFFFFFF</color>
					</lineStyle>
					<lineTo function="true">
						<x>400</x>
						<y>0</y>
					</lineTo>
					<endFill function="true"/>
				</properties>
			</graphics>
		</properties>
	</displayObject>
	*/
	public final class ObjectCreator
	{
		public function ObjectCreator()
		{
			throw new Error("ObjectCreator is a static class. Do not instantiate.");
		}
		
		public static function createAll(xml:XML):Array
		{
			var objects:Array = [];
			var objectsXML:XMLList = xml.children();
			
			for each(var objectXML:XML in objectsXML)
			{
				var object:* = ObjectCreator.create(objectXML);
				
				if(object)
				{
					objects[objects.length] = object;
				}
			}
			
			return objects;
		}
		
		public static function create(objectXML:XML, parentObject:* = null):*
		{
			var object:* = ObjectCreator.parseConstructorXML(objectXML, parentObject);
			
			if(object)
			{
				ObjectCreator.parsePropertiesXML(objectXML, object);
			}
			
			return object;
		}
		
		public static function parseConstructorXML(objectXML:XML, parentObject:* = null):*
		{
			var object:*;
			
			if(!DataUtils.getBoolean(objectXML.attribute("constructed")))
			{
				var objectClass:Class = ClassUtils.getClassByName(objectXML.attribute("class"));
				if(!objectClass)
				{
					trace("ObjectCreator :: parseConstructorXML() ::", objectXML.attribute("class") + " is not a valid class name, or it hasn't been added to the manifest!");
					return null;
				}
				
				if(objectXML.constructor)
				{
					var constructorXML:XMLList = objectXML.constructor.children();
					if(constructorXML.length())
					{
						var properties:Array 	= ObjectCreator.getProperties(constructorXML, parentObject);
						object 					= ObjectCreator.construct(objectClass, properties);
					}
				}
				
				if(!object)
				{
					object = new objectClass();
				}
			}
			else if(parentObject)
			{
				object = parentObject[objectXML.name()];
			}
			
			return object;
		}
		
		public static function parsePropertiesXML(objectXML:XML, object:*):void
		{
			if(objectXML.properties)
			{
				var propertiesXML:XMLList = objectXML.properties.children();
				if(propertiesXML.length())
				{
					var properties:Array = ObjectCreator.getProperties(propertiesXML, object);
					var length:int = properties.length;
					
					for(var i:int = 0; i != length; i++)
					{						
						var propertyXML:XML = propertiesXML[i];
						if(DataUtils.getBoolean(propertyXML.attribute("function")))
						{
							object[propertyXML.name()].apply(null, properties[i]);
						}
						else if(!DataUtils.getBoolean(propertyXML.attribute("constructed")))
						{
							// make sure that component object has public variables that match name (ex: GooglyEyes)
							object[DataUtils.castToType(propertyXML.name())] = properties[i];
						}
					}
				}
			}
		}
		
		private static function getProperties(propertiesXML:XMLList, object:* = null):Array
		{
			var properties:Array = [];
			
			for each(var propertyXML:XML in propertiesXML)
			{
				//Cast to String, perhaps? Avoid the length() check?
				if(propertyXML.attribute("class").length())
				{
					properties.push(ObjectCreator.create(propertyXML, object));
				}
				else if(DataUtils.getBoolean(propertyXML.attribute("function")))
				{
					properties.push(ObjectCreator.getProperties(propertyXML.constructor.children()));
				}
				else
				{
					properties.push(DataUtils.castToType(propertyXML));
				}
			}
			
			return properties;
		}
		
		public static function construct(objectClass:Class, properties:Array = null):*
		{
			try
			{
				if(!properties)
				{
					return new objectClass();
				}
				
				switch(properties.length)
				{
					case 0:
						return new objectClass();
					case 1:
						return new objectClass(properties[0]);
					case 2:
						return new objectClass(properties[0], properties[1]);
					case 3:
						return new objectClass(properties[0], properties[1], properties[2]);
					case 4:
						return new objectClass(properties[0], properties[1], properties[2], properties[3]);
					case 5:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4]);
					case 6:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4], properties[5]);
					case 7:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4], properties[5], properties[6]);
					case 8:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4], properties[5], properties[6], properties[7]);
					case 9:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4], properties[5], properties[6], properties[7], properties[8]);
					case 10:
						return new objectClass(properties[0], properties[1], properties[2], properties[3], properties[4], properties[5], properties[6], properties[7], properties[8], properties[9]);
					default:
						/*
						Haven't fully test how many parameters a constructor can take. Could be more than 10 though.
						Just didn't wanna write a switch into infinity.
						*/
						throw new Error("ObjectCreator.construct() :: Properties cannot exceed a limit of 10.");
						break;
				}
			} 
			catch(error:Error) 
			{
				trace("ObjectCreator.construct() :: A Class of", objectClass, "can't accept these properties [", properties, "].");
			}
		}
	}
}