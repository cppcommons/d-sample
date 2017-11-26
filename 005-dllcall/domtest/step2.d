import qiitadb;

import ddbc;
import hibernated.core;
import std.algorithm;
import std.stdio;

int main()
{
	// Now you can use HibernateD

	// create session
	Session sess = g_SessionFactory.openSession();
	scope (exit)
		sess.close();

	// use session to access DB

	// read all users using query
	Query q = sess.createQuery("FROM User ORDER BY name");
	User[] list = q.list!User();

	writeln(list);

	// create sample data
	Role r10 = new Role();
	r10.name = "role10";
	Role r11 = new Role();
	r11.name = "role11";
	Customer c10 = new Customer();
	c10.name = "Customer 10";
	c10.address = new Address();
	c10.address.zip = "12345";
	c10.address.city = "New York";
	c10.address.streetAddress = "Baker st., 12";
	User u10 = new User();
	u10.name = "Alex";
	u10.customer = c10;
	u10.roles = [r10, r11];
	c10.users = [u10];
	sess.save(r10);
	sess.save(r11);
	sess.save(c10);
	sess.save(u10);

	// load and check data
	User u11 = sess.createQuery("FROM User WHERE name=:Name")
		.setParameter("Name", "Alex").uniqueResult!User();
	assert(u11.roles.length == 2);
	assert(u11.roles[0].name == "role10" || u11.roles.get()[0].name == "role11");
	assert(u11.roles[1].name == "role10" || u11.roles.get()[1].name == "role11");
	assert(u11.customer.name == "Customer 10");
	writeln("u11.customer.users.length=", u11.customer.users.length);
	writeln(u11.customer.users);
	assert(u11.customer.users.length == 1);
	assert(u11.customer.users[0] == u10);
	assert(u11.roles[0].users.length == 1);
	assert(u11.roles[0].users[0] == u10);

	// remove reference
	u11.roles = u11.roles().remove(0);
	sess.update(u11);

	// remove entity
	sess.remove(u11);
	return 0;
}
