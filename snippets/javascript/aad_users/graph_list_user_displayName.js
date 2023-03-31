const users = [];

var results = Array(users.length);

users.forEach((user, index) => {
  $.ajax({
    url: `https://graph.microsoft.com/v1.0/users/${user}`,
    headers: {
      Authorization: "",
    },
  }).done(function (data) {
    results[index] = data.displayName;
    console.log(`done for ${user}`);
  });
});
